class deploy_artifact (
  $package_group,
  $package_name,
  $package_version,
  $package_replicate = false,
  $package_activate = false,
  $package_force = false,
  $path = '/tmp/shinesolutions/aem-aws-stack-provisioner/',
) {

  file { "${path}/${package_group}/${package_name}-${package_version}.zip":
    ensure => absent,
  } ->
  archive { "${path}/${package_group}/${package_name}-${package_version}.zip":
    ensure => present,
    source => "s3://${::databucket}/${::stackprefix}/deployment/${package_group}/${package_name}-${package_version}.zip",
  } ->
  aem_package { "Deploy package ${package_group}/${package_name}-${package_version}" :
    ensure    => present,
    name      => $package_name,
    group     => $package_group,
    version   => $package_version,
    path      => "${path}/${package_group}",
    replicate => $package_replicate,
    activate  => $package_activate,
    force     => $package_force,
  }

}

include deploy_artifact
