class author_dispatcher (
  $conf_dir,
  $docroot_dir,
  $author_port,
) {

  class { 'aem_resources::author_dispatcher_set_config':
    conf_dir    => "${conf_dir}",
    docroot_dir => "${docroot_dir}",
    author_host => 'someauthorhost',
    author_port => "${author_port}",
  } ->
  exec { 'httpd -k graceful':
    cwd  => '/tmp',
    path => ['/sbin'],
  }

}

include author_dispatcher
