File {
  backup => false,
}

class publish_dispatcher (
  $allowed_client = $::publish_dispatcher_allowed_client,
  $publish_host   = $::publishhost,
) {

  class { 'aem_curator::config_aem_tools':
  } -> class { 'aem_curator::config_publish_dispatcher':
    allowed_client => $allowed_client,
    publish_host   => $publish_host,
  }

}

include publish_dispatcher
