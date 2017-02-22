class download_artifacts (
  $base_dir,
  $descriptor_file = $::descriptor_file,
  $component       = $::component,
  $path            = '/tmp/shinesolutions/aem-aws-stack-provisioner',
) {

  # load descriptor file
  $descriptor_hash = loadjson("${path}/${descriptor_file}")
  notify { "The descriptor_hash is: ${descriptor_hash}": }

  # extract component hash
  $component_hash = $descriptor_hash[$component]
  notify { "The component_hash is: ${component_hash}": }

  if $component_hash {

    file { $path:
      ensure => directory,
      mode   => '0775',
    }

    # extract the artifacts hash
    $artifacts = $component_hash['artifacts']
    notify { "The artifacts is: ${artifacts}": }

    if $artifacts {

      class { 'download_dispatcher_artifacts':
        base_dir  => $base_dir,
        artifacts => $artifacts,
        path      => $path,
      }


    } else {

      notify { "no 'artifacts' defined for component: ${component} in descriptor file: ${descriptor_file}. nothing to download": }

    }

    # extract the packages hash
    $packages = $component_hash['packages']
    notify { "The packages is: ${packages}": }

    if $packages {

      class { 'download_packages':
        packages => $packages,
        path     => $path,
      }

    } else {

      notify { "no 'packages' defined for component: ${component} in descriptor file: ${descriptor_file}. nothing to download": }

    }


  } else {

    notify { "component: ${component} not found in descriptor file: ${descriptor_file}. nothing to download": }

  }

}


class download_dispatcher_artifacts (
  $base_dir,
  $artifacts,
  $path = '/tmp/shinesolutions/aem-aws-stack-provisioner',
) {

  file { "${path}/artifacts":
    ensure  => directory,
    mode    => '0775',
    require => File["${path}"],
  }

  $artifacts.each | Integer $index, Hash $artifact| {

    file { "${path}/artifacts/${artifact[name]}":
      ensure  => directory,
      mode    => '0775',
      require => File["${path}/artifacts"],
    }

    archive { "${path}/artifacts/${artifact[name]}.zip":
      ensure       => present,
      extract      => true,
      extract_path => "${path}/artifacts/${artifact[name]}",
      source       => $artifact[source],
      cleanup      => true,
      require      => File["${path}/artifacts/${artifact[name]}"],
      before       => Exec["/usr/bin/python ${base_dir}/aem-tools/generate-artifacts-json.py"]
    }

  }

  #Execute Python script to generate artifacts content json file for deployment.
  exec { "/usr/bin/python ${base_dir}/aem-tools/generate-artifacts-json.py":
    path => '/usr/bin',
  }

}

class download_packages (
  $packages,
  $path = '/tmp/shinesolutions/aem-aws-stack-provisioner',
) {

  # prepare the packages
  file { "${path}/packages":
    ensure  => directory,
    mode    => '0775',
    require => File[$path],
  }

  $packages.each | Integer $index, Hash $package| {

    # TODO: validate the package values exist and populated

    if !defined(File["${path}/packages/${package['group']}"]) {
      file { "${path}/packages/${package['group']}":
        ensure  => directory,
        mode    => '0775',
        require => File["${path}/packages"],
      }
    }

    archive { "${path}/packages/${package['group']}/${package['name']}-${package['version']}.zip":
      ensure  => present,
      source  => $package[source],
      require => File["${path}/packages/${package['group']}"],
      before  => Class['aem_resources::deploy_packages'],
    }

  }

}

include download_artifacts
