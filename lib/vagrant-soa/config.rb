module VagrantPlugins
  module Soa
    class Config < Vagrant.plugin(2, :config)
      attr_accessor :services
      attr_accessor :github_base

      def initialize
        @services = UNSET_VALUE
        @github_base = UNSET_VALUE
      end

      def finalize!
        @services = nil if @services == UNSET_VALUE
        @github_base = nil if @github_base == UNSET_VALUE
      end

      def validate(machine)
        errors = []

        if @services
          if not @services.kind_of?(Hash)
            errors << '`services` must be a hash of form service => {service config hash}'
          end
          @services.each_pair do |service, config|
            if not config.kind_of?(Hash)
              errors << "Invalid configuration for #{service}, config must be a hash, not #{config}"
            end
          end
        end

        return { 'soa' => errors }
      end

    end
  end
end
