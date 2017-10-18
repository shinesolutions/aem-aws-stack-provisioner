File {
  backup => false,
}

class author_publish_dispatcher (
  $base_dir,
  $tmp_dir,

  $credentials_file,
  $publish_protocol,
  $publish_port,

  $aem_id_author_primary = 'author-primary',
) {

  $credentials_hash = loadjson("${tmp_dir}/${credentials_file}")

  class { 'aem_curator::config_aem_tools':
  }
  -> class { 'aem_curator::config_author_primary':
  }
  -> class { 'aem_curator::config_publish':
  }
  -> class { 'aem_curator::config_publish_dispatcher':
  }
  -> aem_replication_agent { 'Create replication agent':
    ensure             => present,
    aem_username       => 'admin',
    aem_password       => $credentials_hash['admin'],
    name               => 'replicationAgent-localhost',
    run_mode           => 'author',
    title              => 'Replication agent for publish localhost',
    description        => 'Replication agent for publish localhost',
    dest_base_url      => "${publish_protocol}://localhost:${publish_port}",
    transport_user     => 'replicator',
    transport_password => $credentials_hash['replicator'],
    log_level          => 'info',
    retry_delay        => 60000,
    force              => true,
    aem_id             => $aem_id_author_primary,
  }

}

include author_publish_dispatcher
