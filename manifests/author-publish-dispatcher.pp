File {
  backup => false,
}

class author_publish_dispatcher (
  $base_dir,
  $tmp_dir,
) {

  notify { 'It works!': }

  #include author_primary

  #class { 'author_primary':
  #  author_port     => '4502',
  #}

}

include author_publish_dispatcher
