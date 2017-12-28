File {
  backup => false,
}

class author_primary (
) {

  class { 'aem_curator::config_aem_tools':
  } -> class { 'aem_curator::config_author_primary':
  }

}

include author_primary
