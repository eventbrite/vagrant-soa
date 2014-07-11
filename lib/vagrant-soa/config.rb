module VagrantPlugins
  module Soa
    class Config < Vagrant.plugin(2, :config)
      attr_accessor :services
      attr_accessor :github_base
      attr_accessor :local_work_dir
      attr_accessor :vagrant_work_dir

      def initialize
        @services = UNSET_VALUE
        @github_base = UNSET_VALUE
        @local_work_dir = UNSET_VALUE
        @vagrant_work_dir = UNSET_VALUE
      end

      def finalize!
        @services = nil if @services == UNSET_VALUE
        @github_base = nil if @github_base == UNSET_VALUE
        @local_work_dir = @local_work_dir == UNSET_VALUE ? nil : File.expand_path(@local_work_dir)
        @vagrant_work_dir = @vagrant_work_dir == UNSET_VALUE ? nil : File.expand_path(@vagrant_work_dir)
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

        if @local_work_dir
          if not File.directory?(@local_work_dir)
            errors << "Specified 'local_work_dir' does not exist: #{@local_work_dir}"
          end
        end

        return { 'soa' => errors }
      end

    end
  end
end
