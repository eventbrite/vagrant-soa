begin
  require 'vagrant'
rescue LoadError
  abort 'vagrant-soa must be loaded in a Vagrant environment.'
end


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
      action_hook 'setup_machine', 'machine_action_up' do |hook|
        require_relative 'actions/setup_machine'
        hook.prepend(Action::SetupMachine)
      end
      action_hook 'setup_machine', 'machine_action_reload' do |hook|
        require_relative 'actions/setup_machine'
        hook.prepend(Action::SetupMachine)
      end

    end
  end
end
