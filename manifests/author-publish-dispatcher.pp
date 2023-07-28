File {
  backup => false,
}

class author_publish_dispatcher (
  $base_dir,
  $tmp_dir,
  $aws_region,
  $docroot_dir,
  $credentials_file,
  $publish_replication_agent_protocol,
  $publish_replication_agent_port,
  $aem_password_retrieval_command,
  $enable_deploy_on_init,
  $aem_repo_devices,
  $dispatcher_data_devices,
  $awslogs_config_path,
  $component                   = $::component,
  $data_bucket_name            = $::data_bucket_name,
  $stack_prefix                = $::stack_prefix,
  $aem_tools_env_path          = '$PATH:/opt/puppetlabs/puppet/bin',
  $aem_id_author_primary       = 'author-primary',
  $ec2_id                      = $::ec2_metadata['instance-id'],
  $log_dir                     = '/var/log/shinesolutions',
  $deploy_timeout              = 1200,
  $enable_cloudwatch_s3_stream = false,
) {

  $credentials_hash = loadjson("${tmp_dir}/${credentials_file}")

  # A simple check for checking if the awslogs(Cloudwatch Agent)
  # configuration file exists or not.
  #
  # We are using this to determine if the cloudwatch agent installation
  # was enabled or disabled while baking the AMIs with packer-aem
  #
  # More information about the find_file function can be found here:
  # https://puppet.com/docs/puppet/5.5/function.html#findfile
  #
  $awslogs_exists = find_file($awslogs_config_path)

  class { 'aem_curator::config_aem_tools':
    aem_tools_env_path => $aem_tools_env_path
  } -> class { 'aem_curator::config_aem_upgrade_tools':
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
    dest_base_url      => "${publish_replication_agent_protocol}://localhost:${publish_replication_agent_port}",
    transport_user     => 'replicator',
    transport_password => $credentials_hash['replicator'],
    log_level          => 'info',
    retry_delay        => 60000,
    force              => true,
    aem_id             => $aem_id_author_primary,
  } -> class { 'deploy_on_init':
    aem_id                => $aem_id_author_primary,
    base_dir              => $base_dir,
    log_dir               => $log_dir,
    tmp_dir               => $tmp_dir,
    exec_path             => ['/bin', '/usr/local/bin', '/usr/bin'],
    enable_deploy_on_init => $enable_deploy_on_init,
    deploy_timeout        => $deploy_timeout,
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
        'aws_region'                     => $aws_region,
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
        'aws_region'                     => $aws_region,
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
        'aws_region'         => $aws_region,
      }
    ),
  }

  ##############################################################################
  # Offline snapshot backup
  ##############################################################################

  file { "${base_dir}/aem-tools/stack-offline-snapshot.sh":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/offline-snapshot-backup-consolidated.sh.epp",
      {
        'base_dir'           => $base_dir,
        'aem_tools_env_path' => $aem_tools_env_path,
        'aem_repo_devices'   => $aem_repo_devices,
        'component'          => $component,
        'stack_prefix'       => $stack_prefix,
        'aws_region'         => $aws_region,
      }
    ),
  }

  ##############################################################################
  # Offline Compaction snapshot backup
  ##############################################################################

  file { "${base_dir}/aem-tools/stack-offline-compaction-snapshot.sh":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/offline-compaction-snapshot-backup-consolidated.sh.epp",
      {
        'base_dir'           => $base_dir,
        'aem_tools_env_path' => $aem_tools_env_path,
        'aem_repo_devices'   => $aem_repo_devices,
        'component'          => $component,
        'stack_prefix'       => $stack_prefix,
        'aws_region'         => $aws_region,
      }
    ),
  }

  ##############################################################################
  # Schedule jobs for live snapshot, offline snapshot & offline compaction snapshot
  ##############################################################################

  file { "${base_dir}/aem-tools/schedule-snapshots.sh":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/schedule-snapshots.sh.epp",
    {
      'aem_tools_env_path' => $aem_tools_env_path,
      'base_dir'           => $base_dir,
      'data_bucket_name'   => $data_bucket_name,
      'stack_prefix'       => $stack_prefix,
      'tmp_dir'            => $tmp_dir,
      'aws_region'         => $aws_region,
      }
    ),
  }

  ##############################################################################
  # Cloudwatch to S3 stream shell script
  ##############################################################################
  if $enable_cloudwatch_s3_stream {
    file { "${base_dir}/aws-tools/cloudwatch-s3-stream.sh":
      ensure  => present,
      content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aws-tools/cloudwatch-s3-stream.sh.epp",
      {
        'aem_tools_env_path' => $aem_tools_env_path,
        'base_dir'           => $base_dir,
        }
      ),
      mode    => '0750',
      owner   => 'root',
      group   => 'root',
    }

    ##############################################################################
    # Cloudwatch to S3 stream python script
    ##############################################################################
    file { "${base_dir}/aws-tools/cloudwatch_logs_subscription.py":
      ensure => present,
      source => "file://${base_dir}/aem-aws-stack-provisioner/files/aws-tools/cloudwatch_logs_subscription.py",
      mode   => '0750',
      owner  => 'root',
      group  => 'root',
    }
  }

  ##############################################################################
  # Update AWS Logs proxy settings file
  # to contain stack_prefix and component name
  ##############################################################################

  # There is only a need to call the update_awslogs class
  # if awslogs is installed.
  if $awslogs_exists {
    class { 'update_awslogs':
      config_file_path => $awslogs_config_path
    }
  }

  exec { 'Resize data volume size of author':
    command => "resize2fs ${aem_repo_devices[0][device_name]}",
    path    => ['/bin', '/usr/local/bin', '/usr/bin', '/usr/sbin'],
  }
  exec { 'Resize data volume size of publish':
    command => "resize2fs ${aem_repo_devices[1][device_name]}",
    path    => ['/bin', '/usr/local/bin', '/usr/bin', '/usr/sbin'],
  }
  exec { 'Resize data volume size of dispatcher':
    command => "resize2fs ${dispatcher_data_devices[0][device_name]}",
    path    => ['/bin', '/usr/local/bin', '/usr/bin', '/usr/sbin'],
  }
}

class deploy_on_init (
  $aem_id,
  $base_dir,
  $log_dir,
  $tmp_dir,
  $exec_path,
  $deploy_timeout,
  $enable_deploy_on_init = false,
) {

  if $enable_deploy_on_init == true {
    exec { 'Deploy Author and Publish AEM packages and Dispatcher artifacts':
      path        => $exec_path,
      environment => ["https_proxy=${::cron_https_proxy}"],
      cwd         => $tmp_dir,
      timeout     => $deploy_timeout,
      command     => "${base_dir}/aem-tools/deploy-artifacts.sh deploy-artifacts-descriptor.json >>${log_dir}/puppet-deploy-artifacts-init.log 2>&1",
      onlyif      => "test `aws s3 ls s3://${data_bucket_name}/${stack_prefix}/deploy-artifacts-descriptor.json | wc -l` -eq 1",
    }
  }

}

class update_awslogs (
  $config_file_path,
  $awslogs_service_name = lookup('common::awslogs_service_name')
) {
  $old_awslogs_content = file($config_file_path)
  $mod_awslogs_content = regsubst($old_awslogs_content, '^log_group_name = ', "log_group_name = ${$stack_prefix}", 'G' )
  $new_awslogs_content = regsubst($mod_awslogs_content, '^log_stream_name = ', "log_stream_name = ${$component}/", 'G' )
  file { 'Update AWS Logs proxy settings file':
    ensure  => file,
    content => $new_awslogs_content,
    path    => $config_file_path,
    before  => Service[$awslogs_service_name],
  } -> service { $awslogs_service_name:
    ensure  => 'running',
    enable  => true,
    require => File['Update AWS Logs proxy settings file'],
  }
}

include author_publish_dispatcher
