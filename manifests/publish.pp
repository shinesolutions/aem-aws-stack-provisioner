File {
  backup => false,
}

class publish (
  $publish_dispatcher_id   = $::pairinstanceid,
  $publish_dispatcher_host = $::publishdispatcherhost,
) {

  class { 'aem_curator::config_aem_tools':
  } -> class { 'aem_curator::config_publish':
    publish_dispatcher_id   => $publish_dispatcher_id,
    publish_dispatcher_host => $publish_dispatcher_host,
  }

}

include publish
