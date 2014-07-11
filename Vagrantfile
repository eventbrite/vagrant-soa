#!/usr/bin/env ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
  config.vm.box = 'precise64'
  config.vm.box_url = 'http://files.vagrantup.com/precise64.box'

  local_work_dir = File.expand_path('./work')
  vagrant_work_dir = '/home/vagrant/work'
  config.vm.synced_folder local_work_dir, vagrant_work_dir

  config.soa.local_work_dir = local_work_dir
  config.soa.vagrant_work_dir = vagrant_work_dir
  config.soa.services = {
    'example_service' => {
      'puppet_path' => 'work/services/example_service/puppet',
      'github_url' => 'git@github.com:eventbrite/vagrant-soa.git'
    },
    'local_service' => {
      'local_path' => 'services/local_service',
    },
  }

  config.vm.provision 'puppet' do |puppet|
    puppet.manifests_path = 'manifests'
    puppet.manifest_file = 'init.pp'
    puppet.module_path = config.puppet_module_registry.get_puppet_module_paths()
  end

end
