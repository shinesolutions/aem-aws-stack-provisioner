class publish_dispatcher (
  $conf_dir,
  $docroot_dir,
  $publish_port,
) {

  class { 'aem_resources::publish_dispatcher_set_config':
    conf_dir     => "${conf_dir}",
    docroot_dir  => "${docroot_dir}",
    publish_host => 'somepublishhost',
    publish_port => "${publish_port}",
  } ->
  exec { 'httpd -k graceful':
    cwd  => '/tmp',
    path => ['/sbin'],
  }

}

include publish_dispatcher
