class author_standby (
  $base_dir,
  $puppet_conf_dir,
  $crx_quickstart_dir,
  $author_protocol,
  $author_port,
) {

  class { 'aem_resources::puppet_aem_resources_set_config':
    conf_dir => "${puppet_conf_dir}",
    protocol => "${author_protocol}",
    host     => 'localhost',
    port     => "${author_port}",
    debug    => true,
  } ->
  class { 'aem_resources::author_standby_set_config':
    crx_quickstart_dir => "${crx_quickstart_dir}",
    primary_host       => "${::authorprimaryhost}",
  } ->
  service { 'aem-aem':
    ensure => 'running',
    enable => true,
  }

  # Set up AEM tools
  file { "${base_dir}/aem-tools/":
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } ->
  file { "${base_dir}/aem-tools/run-event.sh":
    ensure => present,
    source => "${base_dir}/aem-aws-stack-provisioner/files/aem/run-event.sh",
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  }

}

include author_standby
