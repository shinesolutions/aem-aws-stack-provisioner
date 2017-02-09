class author_dispatcher (
  $tmp_dir,
  $dispatcher_conf_dir,
  $httpd_conf_dir,
  $docroot_dir,
  $author_port,
) {

  class { 'aem_resources::author_dispatcher_set_config':
    dispatcher_conf_dir => "${dispatcher_conf_dir}",
    httpd_conf_dir      => "${httpd_conf_dir}",
    docroot_dir         => "${docroot_dir}",
    author_host         => "${::authorhost}",
    author_port         => "${author_port}",
  } ->
  exec { 'httpd -k graceful':
    cwd  => "${tmp_dir}",
    path => ['/sbin'],
  }

}

include author_dispatcher
