File {
  backup => false,
}

class author_dispatcher (
  $author_host = $::authorhost,
) {

  class { 'aem_curator::config_aem_tools':
  } -> class { 'aem_curator::config_author_dispatcher':
    author_host => $author_host,
  }

}

include author_dispatcher
