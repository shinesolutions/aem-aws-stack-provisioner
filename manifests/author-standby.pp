File {
  backup => false,
}

class author_standby (
  $author_primary_host = $::authorprimaryhost,
) {

  class { 'aem_curator::config_aem_tools':
  } -> class { 'aem_curator::config_author_standby':
    author_primary_host => $author_primary_host,
  }

}

include author_standby
