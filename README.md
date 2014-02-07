# vagrant-soa

A [Vagrant](http://www.vagrantup.com/) plugin to handle our SOA infrastructre within vagrant.

## Installation

``` bash
vagrant plugin install vagrant-soa
```

## Usage

This plugin allows you to specify one or more services to run within the VM. By
"services", we mean github repos that define puppet modules which can then be
included in the main manifest.

This structure allows developers of services to easily distribute services to
the rest of the team. Any changes to the service will be synced when users
provision.

Services are defined within the ``Vagrantfile``::

    config.soa.services = {
      'example_service' => {
        'puppet_path' => 'services/example_service/puppet',
        'github_url' => 'git@github.com:eventbrite/vagrant-soa.git',
        'home_dir' => 'services/example_service',
        'branch' => 'test_branch',
      },
    }

The attributes of the service are optional, with the following defaults:

* puppet_path: The location of the puppet module from the root of the service
  repository. If this isn't specified, we'll default to "puppet"
* github_url: The github url for the service. If this isn't provided, we'll
  fallback to: #{config.soa.github_base}/#{service}.git
* branch: The specific branch we want to checkout. Defaults to "master".
* home_dir: The home directory of the service. This is useful if the service
  isn't contained within its own repo.

## Development

``` bash
$ bundle
$ bundle exec vagrant up
```

## Contributing

1. Create your feature branch (`git checkout -b my-new-feature`)
2. Commit your changes (`git commit -am 'Add some feature'`)
3. Push to the branch (`git push origin my-new-feature`)
4. Create new Pull Request
