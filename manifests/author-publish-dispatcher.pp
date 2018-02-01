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

  $aem_repo_devices,
  $component             = $::component,
  $stack_prefix          = $::stack_prefix,
  $env_path              = $::cron_env_path,
  $https_proxy           = $::cron_https_proxy,
  $aem_id_author_primary = 'author-primary',
  $ec2_id                = $::ec2_metadata['instance-id'],
) {

  $credentials_hash = loadjson("${tmp_dir}/${credentials_file}")

  class { 'aem_curator::config_aem_tools':
  } -> class { 'aem_curator::config_aem_deployer':
  } -> class { 'aem_curator::config_author_primary':
  } -> class { 'aem_curator::config_publish':
  } -> class { 'aem_curator::config_publish_dispatcher':
  } -> aem_replication_agent { 'Create replication agent':
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
  } -> class { 'aem_curator::config_collectd':
    component       => $component,
    collectd_prefix => "$stack_prefix-$component-$ec2_id"
  }

  ##############################################################################
  # Live snapshot backup
  ##############################################################################

  file { "${base_dir}/aem-tools/live-snapshot-backup.sh":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/live-snapshot-backup.sh.epp",
      {
        'base_dir'         => $base_dir,
        'aem_repo_devices' => $aem_repo_devices,
        'component'        => $component,
        'stack_prefix'     => $stack_prefix,
      }
    ),
  }

  if $enable_hourly_live_snapshot_cron {
    cron { 'hourly-live-snapshot-backup':
      command     => "${base_dir}/aem-tools/live-snapshot-backup.sh >>/var/log/live-snapshot-backup.log 2>&1",
      user        => 'root',
      hour        => '*',
      minute      => 0,
      environment => ["PATH=${env_path}", "https_proxy=\"${https_proxy}\""],
    }
  }

  ##############################################################################
  # Offline snapshot backup
  ##############################################################################

  file { "${base_dir}/aem-tools/offline-snapshot-backup.sh":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/offline-snapshot-backup.sh.epp",
      {
        'base_dir'         => $base_dir,
        'aem_repo_devices' => $aem_repo_devices,
        'component'        => $component,
        'stack_prefix'     => $stack_prefix,
      }
    ),
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
      command     => "${base_dir}/aem-tools/deploy-artifacts.sh deploy-artifacts-descriptor.json >>/var/log/puppet-deploy-artifacts.log 2>&1",
      onlyif      => "test `aws s3 ls s3://${::data_bucket_name}/${::stack_prefix}/deploy-artifacts-descriptor.json | wc -l` -eq 1",
    }
  }

}

include author_publish_dispatcher
