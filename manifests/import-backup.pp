File {
  backup => false,
}

class import_backup (
  $tmp_dir,
  $source_stack_prefix = $::source_stack_prefix,
  $backup_path         = $::backup_path,
  $package_group       = $::package_group,
  $package_name        = $::package_name,
  $package_version     = $::package_version,
) {

  archive { "${tmp_dir}/${package_group}/${package_name}-${package_version}.zip":
    ensure => present,
    source => "s3://${::data_bucket}/backup/${source_stack_prefix}/${package_group}/${backup_path}/${package_name}-${package_version}.zip",
  } -> aem_package { 'Upload and install backup file':
    ensure  => present,
    name    => $package_name,
    version => $package_version,
    group   => $package_group,
    path    => "${tmp_dir}/${package_group}",
    force   => true,
  } -> file { "${tmp_dir}/${package_group}/${package_name}-${package_version}.zip":
    ensure => absent,
  }

}

include import_backup
