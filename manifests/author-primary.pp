class author_primary (

) {

  class { 'aem_resources::puppet_aem_resources_set_config':
    conf_dir => '/etc/puppetlabs/puppet/',
    protocol => 'http',
    host     => 'localhost',
    port     => 4502,
    debug    => true,
  } ->
  class { 'aem_resources::author_standby_set_config':
    crx_quickstart_dir => '/opt/aem/author/crx-quickstart',
  } ->
  service { 'aem-aem':
    ensure => 'running',
    enable => true,
  } ->
  aem_aem { 'Wait until login page is ready':
    ensure => login_page_is_ready,
  }

}

include author_primary
