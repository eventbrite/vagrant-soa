module VagrantPlugins
  module Soa
    module Errors

      class GitRequired < Vagrant::Errors::VagrantError
        error_key('git_required')
      end

      class UpdatingRepoFailed < Vagrant::Errors::VagrantError
        error_key('git_update_failed')
      end

      class CloningServiceFailed < Vagrant::Errors::VagrantError
        error_key('git_clone_failed')
      end

      class BranchCheckoutFailed < Vagrant::Errors::VagrantError
        error_key('git_checkout_failed')
      end

      class NoGithubUrlProvided < Vagrant::Errors::VagrantError
        error_key('missing_github_url')
      end

    end
  end
end
