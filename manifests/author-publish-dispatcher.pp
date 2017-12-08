File {
  backup => false,
}

class author_publish_dispatcher (
  $base_dir,
  $tmp_dir,

  $credentials_file,
  $publish_protocol,
  $publish_port,

  $enable_deploy_on_init,

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
  } -> class { 'deploy_on_init':
    aem_id                => $aem_id_author_primary,
    base_dir              => $base_dir,
    tmp_dir               => $tmp_dir,
    exec_path             => $exec_path,
    enable_deploy_on_init => $enable_deploy_on_init,
  }

}

class deploy_on_init (
  $aem_id,
  $base_dir,
  $tmp_dir,
  $exec_path             = ['/bin', '/usr/local/bin', '/usr/bin'],
  $enable_deploy_on_init = false,
) {

  if $enable_deploy_on_init == true {
    exec { 'Deploy Author and Publish AEM packages and Dispatcher artifacts':
      path        => $exec_path,
      environment => ["https_proxy=${::cron_https_proxy}"],
      cwd         => $tmp_dir,
      command     => "${base_dir}/aem-tools/deploy-artifacts.sh deploy-artifacts-descriptor.json >>/var/log/deploy-artifacts.log 2>&1",
      onlyif      => "test `aws s3 ls s3://${::data_bucket}/${::stackprefix}/deploy-artifacts-descriptor.json | wc -l` -eq 1",
    }
  }

}

include author_publish_dispatcher
