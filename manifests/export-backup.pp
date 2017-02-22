class export_backup (
  $tmp_dir,
  $package_group   = $::package_group,
  $package_name    = $::package_name,
  $package_version = $::package_version,
  $package_filter  = $::package_filter,
  $backup_path     = $::backup_path,
) {

  file { "${tmp_dir}/${package_group}":
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } ->
  aem_package { 'Create and download backup file':
    ensure  => archived,
    name    => $package_name,
    version => $package_version,
    group   => $package_group,
    path    => "${tmp_dir}/${package_group}",
    filter  => $package_filter,
  } ->
  exec { "aws s3 cp ${tmp_dir}/${package_group}/${package_name}-${package_version}.zip s3://${::data_bucket}/backup/${backup_path}/${package_name}-${package_version}.zip":
    cwd  => $tmp_dir,
    path => ['/bin'],
  } ->
  file { "${tmp_dir}/${package_group}/${package_name}-${package_version}.zip":
    ensure => absent,
  }

}

include export_backup
