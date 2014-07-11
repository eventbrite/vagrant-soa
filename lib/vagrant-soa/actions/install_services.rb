require 'fileutils'
require_relative '../errors'

module VagrantPlugins
  module Soa
    class Action
      class InstallServices

        def initialize(app, env)
          @app = app
          @env = env
          @soa = env[:machine].config.soa
          @puppet_fact_generator = env[:machine].config.puppet_fact_generator
          @puppet_module_registry = env[:machine].config.puppet_module_registry
          @git = get_local_git()
          # we use the local_data_path of the machine since vagrant ensures it
          # exists as well as mounts it to the VM for us.
          @install_dir = env[:machine].env.local_data_path.join('services')
          # this "/vagrant" dir is hard coded in vagrant as well:
          # https://github.com/mitchellh/vagrant/blob/master/plugins/kernel_v2/config/vm.rb#L385-L389
          @vagrant_install_dir = '/vagrant/.vagrant/services'
        end

        # Get the proper git to clone the service repos.
        def get_local_git
          git = `which git`.chomp
          if git == ""
            raise Soa::Errors::GitRequired.new
          else
            return git
          end
        end

        def update_repo(service, target_branch, pwd, chdir_on_success=true)
          # make sure the branch is up to date
          updated = system "#{@git} pull --rebase"
          if not updated
            # pop back to the original directory
            Dir.chdir pwd
            raise Soa::Errors::UpdatingRepoFailed,
              target_branch: target_branch,
              service: service
          else
            # pop back to the original directory
            if chdir_on_success
              Dir.chdir pwd
            end
            @env[:ui].success(
              "Successfully updated branch: #{target_branch} for #{service}"
            )
          end
        end

        # When installing a service we have to clone the service repository.
        # Ideally, we would manage these modules with librarian-puppet and the
        # Puppetfile, but because services depend on files that aren't
        # contained within their puppet module (ie. requirements.txt or uwsgi
        # handlers etc.), cloning the repo is the next best solution.
        def clone_service_repo(service, config)
          target_directory = File.join @install_dir, service

          # make sure the repo is checked out
          if File.directory? target_directory
            @env[:ui].info "Service: #{service} is already checked out"
          else
            if not config['github_url'] || @soa.github_base
              raise Soa::Errors::NoGithubUrlProvided,
                service: service
            end

            github_target = config['github_url'] ? config['github_url'] : "#{@soa.github_base}/#{service}.git"
            @env[:ui].info(
              "Cloning service: #{service} (#{github_target}) to target directory:"\
              " #{target_directory}"
            )
            success = system "#{@git} clone --recurse-submodules #{github_target} #{target_directory}"
            if not success
              raise Soa::Errors::CloningServiceFailed,
                service: service
            else
              @env[:ui].success "Successfully checked out service: #{service}"
            end
          end

          # move to the target_directory so we can examine it with git
          pwd = Dir.pwd
          Dir.chdir(target_directory)
          update_repo = true

          # don't attempt to auto-update if we've found any changes in the repo we
          # already have checked out (stolen from boxen)
          clean = `#{@git} status --porcelain`.empty?
          current_branch = `#{@git} rev-parse --abbrev-ref HEAD`.chomp
          fast_forwardable = `#{@git} rev-list --count origin/master..master`.chomp == '0'
          if current_branch.empty?
            ref = `#{@git} log -1 --pretty=format:%h`
            @env[:ui].warn "#{service} not currently on any branch (ref: #{ref}), won't auto-update!"
            update_repo = false
          elsif !fast_forwardable
            @env[:ui].warn "#{service}'s master branch is out of sync, won't auto-update!"
            update_repo = false
          elsif !clean
            @env[:ui].warn "#{service} has a dirty tree, won't auto-update!"
            update_repo = false
          end

          # make sure we're on the correct branch
          target_branch = config.fetch('branch', 'master')
          if !update_repo
            # pop back to the original directory
            Dir.chdir(pwd)
            return target_directory
          elsif target_branch != current_branch
            # we have to pull first to ensure that we have all available branches
            update_repo(service, current_branch, pwd, false)
            checkout_target = system("#{@git} checkout #{target_branch}")
            if not checkout_target
              # pop back to the original directory
              Dir.chdir(pwd)
              raise Soa::Errors::BranchCheckoutFailed,
                target_branch: target_branch,
                service: service
            else
              @env[:ui].success(
                "Successfully checked out branch: #{target_branch}"\
                " for service #{service}"
              )
            end
          end

          if clean
            update_repo(service, target_branch, pwd)
          end
          return target_directory
        end

        # When services are installed they can specify a 'home_dir' in their
        # vagrant config. This needs to be a path that exists within the VM and
        # points to their desired home directory.
        #
        #   These custom facts will be of the form: "#{service}_home_dir"
        def register_service_home_fact(service, config)
          home_dir = config.fetch('home_dir', nil)
          # not sure if there is a better way to do this in ruby, we don't want a
          # trailing slash if "home_dir" is empty
          if home_dir
            full_path = File.join(
              @vagrant_install_dir,
              service,
              home_dir
            )
          else
            full_path = File.join(
              @vagrant_install_dir,
              service
            )
          end
          if File.directory?(full_path)
            @env[:ui].warn "Invalid home_dir passed for service:"\
              " #{service}, home_dir: #{full_path}"
          else
            @puppet_fact_generator.add_fact("#{service}_home_dir", full_path)
          end
        end

        def symlink_local_service(service, config)
          target_directory = File.join @install_dir, service
          FileUtils.symlink File.expand_path(config['local_path'], @soa.vagrant_work_dir), target_directory, :force => true
          @env[:ui].info "Symlinking local service: #{service} to #{target_directory}"
          return target_directory
        end

        # To install a service we clone the service repo and add the puppet
        # path to @puppet_module_registry.puppet_module_paths.
        def install_service(service, config)
          if config.has_key?('local_path')
            if not @soa.local_work_dir and not @soa.vagrant_work_dir
              @env[:ui].error "You must specify 'config.soa.local_work_dir' and 'config.soa.vagrant_work_dir' to setup a local service"
              return
            end
            target_directory = symlink_local_service(service, config)
            puppet_directory = File.expand_path(config['local_path'], @soa.local_work_dir)
          else
            target_directory = clone_service_repo(service, config)
            puppet_directory = target_directory
          end
          puppet_path = config.fetch('puppet_path', 'puppet')
          full_path = File.join(puppet_directory, puppet_path)
          register_service_home_fact(service, config)
          @puppet_module_registry.register_module_path(service, full_path)
        end

        # If any services are specified, install them
        def install_services()
          if @soa.services
            @soa.services.each_pair do |service, config|
              install_service(service, config)
            end
          end
        end

        def call(env)
          # determine if provision is enabled, if we provided the
          # "--no-provision" flag this would be false. if it isn't present, we
          # should consider provision enabled
          provision_enabled = env.has_key?(:provision_enabled) ? env[:provision_enabled] : true
          install_services() if provision_enabled
          @app.call(env)
        end

      end
    end
  end
end
