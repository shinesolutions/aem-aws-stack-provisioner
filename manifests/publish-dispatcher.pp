class publish_dispatcher (
  $dispatcher_conf_dir,
  $httpd_conf_dir,
  $docroot_dir,
  $publish_port,
) {

  class { 'aem_resources::publish_dispatcher_set_config':
    dispatcher_conf_dir => "${dispatcher_conf_dir}",
    httpd_conf_dir      => "${httpd_conf_dir}",
    docroot_dir         => "${docroot_dir}",
    publish_host         => "${::publishhost}",
    publish_port         => "${publish_port}",
  } ->
  exec { 'httpd -k graceful':
    cwd  => '/tmp',
    path => ['/sbin'],
  }

}

include publish_dispatcher
