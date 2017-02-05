class deploy_artifacts (
  $descriptor = $::descriptor,
  $component  = $::component,
  $path       = '/tmp/deploy_artifacts'
) {

  # load descriptor file
  $descriptor_hash = loadjson($descriptor)
  notify { "The descriptor_hash is: ${descriptor_hash}": }

  # extract component hash
  $component_hash = $descriptor_hash[$component]
  notify { "The component_hash is: ${component_hash}": }

  if $component_hash {

    file { $path:
      ensure => directory,
      mode   => '0775',
    }

    # TODO: If configurations exists send to deploy configurations

    # extract the configurations hash
    $configurations = $component_hash['configurations']
    notify { "The configurations is: ${configurations}": }

    if $configurations {

      file { "${path}/configurations":
        ensure  => directory,
        mode    => '0775',
        require => File[$path],
      }

      $configurations.each | Integer $index, Hash $configuration| {

        archive { "${path}/configurations/${configuration[filename]}":
          ensure => present,
          source => $configuration[source],
        } ->
          file { $configuration[destination]:
            ensure => present,
            group  => $configuration[group],
            owner  => $configuration[owner],
            mode   => $configuration[mode],
            source => "${path}/configurations/${configuration[filename]}",
          }

        #TODO: optional exec command to restart service. post file placement.
        if $configuration[exec_command] {

          exec { $configuration[exec_command]:
            require => File[$configuration[destination]],
          }

        }

      }

    }


    # extract the packages hash
    $packages = $component_hash['packages']
    notify { "The packages is: ${packages}": }

    # TODO: If packages exists send to deploy packages

    if $packages {

      # prepare the packages
      file { "${path}/packages":
        ensure  => directory,
        mode    => '0775',
        require => File[$path],
      }

      $packages.each | Integer $index, Hash $package| {

        # TODO: validate the package values exist and populated?

        if !defined(File["${path}/packages/${package['group']}"]) {
          file { "${path}/packages/${package['group']}":
            ensure  => directory,
            mode    => '0775',
            require => File["${path}/packages"],
          }
        }

        if !defined(File["${path}/packages/${package['group']}/${package['name']}"]) {
          file { "${path}/packages/${package['group']}/${package['name']}":
            ensure  => directory,
            mode    => '0775',
            require => File["${path}/packages/${package['group']}"],
          }
        }

        file { "${path}/packages/${package['group']}/${package['name']}/${package['version']}":
          ensure  => directory,
          mode    => '0775',
          require => File["${path}/packages/${package['group']}/${package['name']}"],
        } ->
          archive { "${path}/packages/${package['group']}/${package['name']}/${package['version']}/${package['name']}-${package['version']}.zip":
            ensure => present,
            source => $package[source],
            before => Class['aem_resources::deploy_packages'],
          }

      }

      class { 'aem_resources::deploy_packages':
        packages => $packages,
        path     => $path,
      }

    } else {

      notify { "no 'packages' defined for component: ${component} in descriptor file: ${descriptor}. nothing to deploy": }

    }


  } else {

    notify { "component: ${component} not found in descriptor file: ${descriptor}. nothing to deploy": }

  }

}

include deploy_artifacts
