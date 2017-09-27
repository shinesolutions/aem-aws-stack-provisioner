File {
  backup => false,
}

class author_publish_dispatcher (
  $base_dir,
  $tmp_dir,
) {

  include aem_curator::config_author_primary
  include aem_curator::config_publish
  include aem_curator::config_publish_dispatcher

}

include author_publish_dispatcher
