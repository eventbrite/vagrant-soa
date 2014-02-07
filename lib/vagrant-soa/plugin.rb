begin
  require 'vagrant'
rescue LoadError
  abort 'vagrant-soa must be loaded in a Vagrant environment.'
end

begin
  require 'vagrant-puppet-module-registry'
rescue LoadError
  abort 'vagrant-soa depends on the `vagrant-puppet-module-registry` plugin.'
end

# Add our custom translations to the load path
I18n.load_path << File.expand_path("../../../locales/en.yml", __FILE__)

module VagrantPlugins
  module Soa
    class Plugin < Vagrant.plugin('2')
      name 'vagrant-soa'
      description <<-DESC
A Vagrant plugin to manage vagrant SOA infrastructure.
DESC

      # define configs
      config 'soa' do
        require_relative 'config'
        Config
      end

      # define hooks
      action_hook 'install_services' do |hook|
        require_relative 'actions/install_services'
        # we need to install services before we AddModuleFacts
        hook.before VagrantPlugins::PuppetModuleRegistry::Action::AddModuleFacts, Action::InstallServices
      end

    end
  end
end
