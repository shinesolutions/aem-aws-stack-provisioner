class author_primary (
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
  class { 'aem_resources::author_primary_set_config':
    crx_quickstart_dir => "${crx_quickstart_dir}",
  } ->
  service { 'aem-aem':
    ensure => 'running',
    enable => true,
  } ->
  aem_aem { 'Wait until login page is ready':
    ensure                     => login_page_is_ready,
    retries_max_tries          => 60,
    retries_base_sleep_seconds => 5,
    retries_max_sleep_seconds  => 5,
  }

  # Set up AEM tools
  file { "${base_dir}/aem-tools/":
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } ->
  file { "${base_dir}/aem-tools/run-event.sh":
    ensure  => present,
    source  => "${base_dir}/aem-aws-stack-provisioner/files/aem/run-event.sh",
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }
}

include author_primary
