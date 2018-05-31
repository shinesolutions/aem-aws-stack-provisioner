File {
  backup => false,
}

class author_publish_dispatcher (
  $base_dir,
  $tmp_dir,
  $docroot_dir,
  $credentials_file,
  $publish_protocol,
  $publish_port,
  $aem_password_retrieval_command,
  $enable_deploy_on_init,
  $aem_repo_devices,
  $component             = $::component,
  $data_bucket_name      = $::data_bucket_name,
  $stack_prefix          = $::stack_prefix,
  $aem_tools_env_path    = '$PATH:/opt/puppetlabs/puppet/bin',
  $aem_id_author_primary = 'author-primary',
  $ec2_id                = $::ec2_metadata['instance-id'],
  $log_dir               = '/var/log/shinesolutions',
) {

  $credentials_hash = loadjson("${tmp_dir}/${credentials_file}")

  class { 'aem_curator::config_aem_tools':
    aem_tools_env_path => $aem_tools_env_path
  } -> class { 'aem_curator::config_aem_tools_dispatcher':
    aem_tools_env_path => $aem_tools_env_path
  } -> class { 'aem_curator::config_aem_deployer':
    aem_tools_env_path => $aem_tools_env_path
  } -> class { 'aem_curator::config_author_primary':
  } -> class { 'aem_curator::config_publish':
  } -> class { 'aem_curator::config_publish_dispatcher':
    docroot_dir => $docroot_dir,
  } -> class { 'aem_curator::config_logrotate':
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
    collectd_prefix => "${stack_prefix}-${component}",
    ec2_id          => $ec2_id
  } -> class { 'aem_curator::config_aem_scheduled_jobs':
  }

  ##############################################################################
  # Export backups to S3
  ##############################################################################

  file { "${base_dir}/aem-tools/export-backup.sh":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/export-backup.sh.epp",
      {
        'base_dir'                       => $base_dir,
        'aem_tools_env_path'             => $aem_tools_env_path,
        'aem_password_retrieval_command' => $aem_password_retrieval_command,
      }
    ),
  }

  file { "${base_dir}/aem-tools/export-backups.sh":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/export-backups.sh.epp",
      {
        'base_dir'                       => $base_dir,
        'aem_tools_env_path'             => $aem_tools_env_path,
        'aem_password_retrieval_command' => $aem_password_retrieval_command,
      }
    ),
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
        'base_dir'           => $base_dir,
        'aem_tools_env_path' => $aem_tools_env_path,
        'aem_repo_devices'   => $aem_repo_devices,
        'component'          => $component,
        'stack_prefix'       => $stack_prefix,
      }
    ),
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
        'base_dir'           => $base_dir,
        'aem_tools_env_path' => $aem_tools_env_path,
        'aem_repo_devices'   => $aem_repo_devices,
        'component'          => $component,
        'stack_prefix'       => $stack_prefix,
      }
    ),
  }

  ##############################################################################
  # Schedule jobs for offline snapshot & offline compaction snapshot
  ##############################################################################

  file { "${base_dir}/aem-tools/schedule-offline-snapshots.sh":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/schedule-offline-snapshots.sh.epp",
    {
      'aem_tools_env_path' => $aem_tools_env_path,
      'base_dir'           => $base_dir,
      'data_bucket_name'   => $data_bucket_name,
      'stack_prefix'       => $stack_prefix,
      'tmp_dir'            => $tmp_dir
      }
    ),
  }

  ##############################################################################
  # AEM Readiness test
  ##############################################################################

  file { "${base_dir}/aem-tools/test-readiness.sh":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/test-readiness.sh.epp",
      {
        'aem_tools_env_path' => $aem_tools_env_path,
        'base_dir'           => $base_dir,
      }
    ),
  }

  ##############################################################################
  # Update /etc/awslogs/awslogs.conf
  # to contain stack_prefix and component name
  ##############################################################################

  class { 'update_awslogs': }
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
      command     => "${base_dir}/aem-tools/deploy-artifacts.sh deploy-artifacts-descriptor.json >>${log_dir}/puppet-deploy-artifacts-init.log 2>&1",
      onlyif      => "test `aws s3 ls s3://${data_bucket_name}/${stack_prefix}/deploy-artifacts-descriptor.json | wc -l` -eq 1",
    }
  }

}

class update_awslogs (
  $old_awslogs_content = file('/etc/awslogs/awslogs.conf'),
) {
  service { 'awslogs':
    ensure => 'running',
    enable => true
  }
  $mod_awslogs_content = regsubst($old_awslogs_content, '^log_group_name = ', "log_group_name = ${$stack_prefix}", 'G' )
  $new_awslogs_content = regsubst($mod_awslogs_content, '^log_stream_name = ', "log_stream_name = ${$component}/", 'G' )
  file { 'Update file /etc/awslogs/awslogs.conf':
    ensure  => file,
    content => $new_awslogs_content,
    path    => '/etc/awslogs/awslogs.conf',
    notify  => Service['awslogs'],
  }
}

include author_publish_dispatcher
