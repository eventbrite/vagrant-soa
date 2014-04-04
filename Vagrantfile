#!/usr/bin/env ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
  config.vm.box = 'precise64'
  config.vm.box_url = 'http://files.vagrantup.com/precise64.box'

  config.soa.services = {
    'example_service' => {
      'puppet_path' => 'services/example_service/puppet',
      'github_url' => 'git@github.com:eventbrite/vagrant-soa.git'
    },
  }

  config.vm.provision 'puppet' do |puppet|
    puppet.manifests_path = 'manifests'
    puppet.manifest_file = 'init.pp'
    puppet.module_path = config.puppet_module_registry.get_puppet_module_paths()
  end

end
