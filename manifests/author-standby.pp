class author_standby (

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
    primary_host       => "${::authorprimaryhost}",
  } ->
  service { 'aem-aem':
    ensure => 'running',
    enable => true,
  }

}

include author_standby
