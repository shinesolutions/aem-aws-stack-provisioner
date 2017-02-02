class aem_packages (
  $descriptor = $::descriptor,
  $component  = $::component,
  $path       = '/tmp/aem_packages'
) {

  # load descriptor file
  $descriptor_hash = loadjson($descriptor)
  notify { "The descriptor_hash is: ${descriptor_hash}": }


  # extract component hash
  $component_hash = $descriptor_hash[$component]
  notify { "The component_hash is: ${component_hash}": }

  if $component_hash {

    # extract the packages hash
    $packages = $component_hash['packages']
    notify { "The packages is: ${packages}": }

    if $packages {

      # prepare the packages
      file { $path:
        ensure => directory,
        mode   => '0775',
      }

      $packages.each | Integer $index, Hash $package| {

        if !defined(File["${path}/${package['group']}"]) {
          file { "${path}/${package['group']}":
            ensure  => directory,
            mode    => '0775',
            require => File[$path],
          }
        }

        if !defined(File["${path}/${package['group']}/${package['name']}"]) {
          file { "${path}/${package['group']}/${package['name']}":
            ensure  => directory,
            mode    => '0775',
            require => File["${path}/${package['group']}"],
          }
        }

        file { "${path}/${package['group']}/${package['name']}/${package['version']}":
          ensure  => directory,
          mode    => '0775',
          require => File["${path}/${package['group']}/${package['name']}"],
        } ->
          file { "${path}/${package['group']}/${package['name']}/${package['version']}/${package['name']}-${package['version']}.zip":
            ensure => file,
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

include aem_packages
