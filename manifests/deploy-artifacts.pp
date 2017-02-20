class deploy_artifacts (
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

    # extract the asset hash
    $asset = $component_hash['asset']
    notify { "The asset is: ${asset}": }

    if $asset {

      class { 'deploy_asset':
        asset => $asset,
        path  => $path,
      }


    } else {

      notify { "no 'asset' defined for component: ${component} in descriptor file: ${descriptor_file}
         . nothing to deploy": }

    }

    # extract the packages hash
    $packages = $component_hash['packages']
    notify { "The packages is: ${packages}": }

    if $packages {

      class { 'deploy_packages':
        packages => $packages,
        path     => $path,
      }

    } else {

      notify { "no 'packages' defined for component: ${component} in descriptor file: ${descriptor_file}
        . nothing to deploy": }

    }


  } else {

    notify { "component: ${component} not found in descriptor file: ${descriptor_file}. nothing to deploy": }

  }

}


class deploy_asset (
  $asset,
  $path = '/tmp/shinesolutions/aem-aws-stack-provisioner',
) {

  file { "${path}/asset":
    ensure  => directory,
    mode    => '0775',
    require => File["${path}"],
  }

  file { "${path}/asset/${asset[name]}":
    ensure  => directory,
    mode    => '0775',
    require => File["${path}/asset"],
  }

  archive { "${path}/asset/${asset[name]}.zip":
    ensure       => present,
    extract      => true,
    extract_path => "${path}/asset/${asset[name]}",
    source       => $asset[source],
    cleanup      => true,
    require      => File["${path}/asset/${asset[name]}"],
  }

  # Execute the pre-config script if exists
  # exec { 'check_pre_config_presence':
  #   command => '/bin/true',
  #   onlyif  => "/usr/bin/test -f ${path}/asset/${asset[name]}/pre-config.sh",
  #   require => Archive["${path}/asset/${asset[name]}.zip"],
  # }

  exec { "${path}/asset/${asset[name]}/pre-config.sh":
    command => "/bin/bash -c '${path}/asset/${asset[name]}/pre-config.sh'",
    onlyif  => "/usr/bin/test -f ${path}/asset/${asset[name]}/pre-config.sh",
    before  => File["${path}/asset/${asset[name]}/httpd"]
  }


  file { "${path}/asset/${asset[name]}/httpd":
    ensure  => directory,
    mode    => '0775',
    require => File["${path}/asset/${asset[name]}"],
  }

  # copy the conf/ files into /etc/httpd/conf
  file { "${path}/asset/${asset[name]}/httpd/conf":
    ensure  => 'directory',
    mode    => '0755',
    require => File["${path}/asset/${asset[name]}/httpd"],
  }

  file { '/etc/httpd/conf':
    ensure       => directory,
    source       => "${path}/asset/${asset[name]}/httpd/conf",
    sourceselect => all,
    owner        => root,
    group        => root,
    recurse      => true,
    require      => File["${path}/asset/${asset[name]}/httpd/conf"],
  }


  # copy the conf.d/ files into /etc/httpd/conf.d
  file { "${path}/asset/${asset[name]}/httpd/conf.d":
    ensure  => 'directory',
    mode    => '0755',
    require => File["${path}/asset/${asset[name]}/httpd"],
  }

  file { '/etc/httpd/conf.d':
    ensure       => directory,
    source       => "${path}/asset/${asset[name]}/httpd/conf.d",
    sourceselect => all,
    owner        => root,
    group        => root,
    recurse      => true,
    require      => File["${path}/asset/${asset[name]}/httpd/conf.d"],
  }


  # copy the conf.modules.d/ files into /etc/httpd/conf.modules.d
  file { "${path}/asset/${asset[name]}/httpd/conf.modules.d":
    ensure  => 'directory',
    mode    => '0755',
    require => File["${path}/asset/${asset[name]}"],
  }

  file { '/etc/httpd/conf.modules.d':
    ensure       => directory,
    source       => "${path}/asset/${asset[name]}/httpd/conf.modules.d",
    sourceselect => all,
    owner        => root,
    group        => root,
    recurse      => true,
    require      => File["${path}/asset/${asset[name]}/httpd/conf.modules.d"],
  }

  # Set the ServerName value in the httpd.conf file
  file { '/etc/httpd/conf/httpd.conf':
    ensure => present,
  } ->
    file_line { 'Set the ServerName in httpd.conf file':
      path    => '/etc/httpd/conf/httpd.conf',
      line    => "ServerName \"${trusted[certname]}\"",
      match   => '^ServerName.*$',
      require => File['/etc/httpd/conf.d/'],
    }

  # Execute the post-config script if exists
  # exec { 'check_post_config_presence':
  #   command => '/bin/true',
  #   onlyif  => "/usr/bin/test -f ${path}/asset/post-config.sh",
  #   require => Archive["${path}/asset/${asset[name]}.zip"],
  # }

  exec { "${path}/asset/post-config.sh":
    command => "/bin/bash -c '${path}/asset/${asset[name]}/post-config.sh'",
    onlyif  => "/usr/bin/test -f ${path}/asset/post-config.sh",
    require => [
      # Exec['check_post_config_presence'],
      File['/etc/httpd/conf/'],
      File['/etc/httpd/conf.d/'],
      File['/etc/httpd/conf.modules.d/'],
      File_line['Set the ServerName in httpd.conf file']
    ],
  }

}

class deploy_packages (
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

  class { 'aem_resources::deploy_packages':
    packages => $packages,
    path     => "${path}/packages/",
  }


}


include deploy_artifacts
