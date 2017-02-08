class publish (

) {

  class { 'aem_resources::puppet_aem_resources_set_config':
    conf_dir => '/etc/puppetlabs/puppet/',
    protocol => 'http',
    host     => 'localhost',
    port     => 4503,
    debug    => true,
  } ->
  service { 'aem-aem':
    ensure => 'running',
    enable => true,
  } ->
  aem_aem { 'Wait until login page is ready':
    ensure  => login_page_is_ready,
  } ->
  aem_flush_agent { 'Create flush agent':
    ensure        => present,
    name          => "flushAgent-${::pairinstanceid}",
    run_mode      => 'publish',
    title         => "Flush agent for publish-dispatcher ${::pairinstanceid}",
    description   => "Flush agent for publish-dispatcher ${::pairinstanceid}",
    dest_base_url => "http://${::publishdispatcherhost}:80",
    log_level     => 'info',
    retry_delay   => 60000,
    force         => true,
  }

}

include publish
