File {
  backup => false,
}

class publish (
  $base_dir,
  $exec_path,
  $tmp_dir,
  $aem_repo_devices,
  $aem_password_retrieval_command,
  $volume_type,
  $revert_snapshot_type,
  $awslogs_config_path,
  $publish_dispatcher_id   = $::pairinstanceid,
  $publish_dispatcher_host = $::publishdispatcherhost,
  $stack_prefix            = $::stack_prefix,
  $component               = $::component,
  $env_path                = $::cron_env_path,
  $aem_tools_env_path      = '$PATH:/opt/puppetlabs/puppet/bin',
  $https_proxy             = $::cron_https_proxy,
  $ec2_id                  = $::ec2_metadata['instance-id'],
  $snapshotid              = $::snapshotid,
) {

  if $snapshotid != undef and $snapshotid != '' {
    # In the future we maybe disable services like awslogs
    # during baking and activate them during provisioning

    exec { 'create awslogs temp dir':
      command => 'mkdir /tmp/awslogs',
      path    => $exec_path,
      before  => Exec['Enable awslogs CronJobs']
    } -> exec { 'Disable awslogs CronJobs':
      command => 'mv /etc/cron.d/awslogs* /tmp/awslogs/',
      path    => $exec_path,
    } -> exec { 'Prevent awslogs service from restart':
      command => 'systemctl disable awslogs',
      path    => $exec_path,
    } -> exec { 'Stopping all access to mounted FS':
      command => 'systemctl stop awslogs',
      path    => $exec_path,
    } -> exec { "Attach volume from snapshot ID ${snapshotid}":
      command => "${base_dir}/aws-tools/snapshot_attach.py --device ${aem_repo_devices[0][device_name]} --device-alias ${aem_repo_devices[0][device_alias]} --volume-type ${volume_type} --snapshot-id ${snapshotid} -vvvv",
      path    => $exec_path,
    }

    exec { 'Sleep 15 seconds before allowing access the mounted FS':
      command => 'sleep 15',
      path    => $exec_path,
      require => Exec["Attach volume from snapshot ID ${snapshotid}"],
      before  => [
        Class['aem_curator::config_publish'],
        Class['update_awslogs']
      ]
    }
  }

  class { 'aem_curator::config_aem_tools':
    aem_tools_env_path => $aem_tools_env_path
  } -> class { 'aem_curator::config_aem_upgrade_tools':
    aem_tools_env_path => $aem_tools_env_path
  } -> class { 'aem_curator::config_aem_deployer':
    aem_tools_env_path => $aem_tools_env_path
  } -> class { 'aem_curator::config_publish':
    publish_dispatcher_id   => $publish_dispatcher_id,
    publish_dispatcher_host => $publish_dispatcher_host,
  } -> class { 'aem_curator::config_logrotate':
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
        'aem_tools_env_path'             => $aem_tools_env_path,
        'base_dir'                       => $base_dir,
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
        'aem_tools_env_path'             => $aem_tools_env_path,
        'base_dir'                       => $base_dir,
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
        'aem_tools_env_path'   => $aem_tools_env_path,
        'base_dir'             => $base_dir,
        'aem_repo_devices'     => $aem_repo_devices,
        'component'            => $component,
        'stack_prefix'         => $stack_prefix,
        'revert_snapshot_type' => $revert_snapshot_type,
      }
    )
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
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/offline-snapshot-backup-full-set.sh.epp",
      {
        'aem_tools_env_path'   => $aem_tools_env_path,
        'base_dir'             => $base_dir,
        'aem_repo_devices'     => $aem_repo_devices,
        'component'            => $component,
        'stack_prefix'         => $stack_prefix,
        'revert_snapshot_type' => $revert_snapshot_type,
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
      'tmp_dir'            => $tmp_dir
      }
    ),
  }

  ##############################################################################
  # Enter and exit standby in AutoScalingGroup
  ##############################################################################

  file { "${base_dir}/aem-tools/enter-standby.sh":
    ensure => present,
    source => "file://${base_dir}/aem-aws-stack-provisioner/files/aem-tools/enter-standby.sh",
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } -> file { "${base_dir}/aem-tools/exit-standby.sh":
    ensure => present,
    source => "file://${base_dir}/aem-aws-stack-provisioner/files/aem-tools/exit-standby.sh",
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  }

  ##############################################################################
  # Update AWS Logs proxy settings file
  # to contain stack_prefix and component name
  ##############################################################################

  class { 'update_awslogs':
    config_file_path => $awslogs_config_path,
    exec_path        => $exec_path,
    before           => Class['aem_curator::config_publish']
  }
}

class update_awslogs (
  $config_file_path,
  $exec_path,
  $awslogs_service_name = lookup('common::awslogs_service_name')
) {
  exec { 'Enable awslogs CronJobs':
    command => 'mv /tmp/awslogs/* /etc/cron.d/',
    path    => $exec_path,
    onlyif  => '/usr/bin/test -e /tmp/awslogs',
    before  => Service[$awslogs_service_name]
  }

  service { $awslogs_service_name:
    ensure => 'running',
    enable => true,
  }

  $old_awslogs_content = file($config_file_path)
  $mod_awslogs_content = regsubst($old_awslogs_content, '^log_group_name = ', "log_group_name = ${$stack_prefix}", 'G' )
  $new_awslogs_content = regsubst($mod_awslogs_content, '^log_stream_name = ', "log_stream_name = ${$component}/", 'G' )
  file { 'Update AWS Logs proxy settings file':
    ensure  => file,
    content => $new_awslogs_content,
    path    => $config_file_path,
    notify  => Service[$awslogs_service_name],
  }
}

include publish
