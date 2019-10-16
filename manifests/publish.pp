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
  $awslogs_service_name    = lookup('common::awslogs_service_name'),
  $publish_dispatcher_id   = $::pairinstanceid,
  $publish_dispatcher_host = $::publishdispatcherhost,
  $stack_prefix            = $::stack_prefix,
  $component               = $::component,
  $env_path                = $::cron_env_path,
  $aem_tools_env_path      = '$PATH:/opt/puppetlabs/puppet/bin',
  $https_proxy             = $::cron_https_proxy,
  $ec2_id                  = $::ec2_metadata['instance-id'],
  $snapshotid              = $::snapshotid,
  $snapshot_attach_timeout = 900,
) {

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

  if $snapshotid != undef and $snapshotid != '' {
    # In the future we maybe disable services like awslogs
    # during baking and activate them during provisioning

    # there is only a need to make sure cloudwatch agent is
    # not running when awslogs service is installed.
    if $awslogs_exists {
      exec { 'create awslogs cron temp dir':
        command => 'mkdir -p /tmp/shinesolutions/crons/awslogs',
        path    => $exec_path,
        before  => [
                      Exec['Enable awslogs CronJobs'],
                      Exec['Disable awslogs CronJobs'],
                    ],
        onlyif  => 'ls /etc/cron.d/awslogs*'
      } -> exec { 'Disable awslogs CronJobs':
        command => 'mv /etc/cron.d/awslogs* /tmp/shinesolutions/crons/awslogs/',
        path    => $exec_path,
        onlyif  => 'ls /etc/cron.d/awslogs*',
        require => Exec['create awslogs cron temp dir'],
        before  => [
                    Exec['Enable awslogs CronJobs'],
                    Exec['Prevent awslogs service from restart'],
                    Exec['Stopping awslogs service to prevent it from accessing mounted FS']
                  ],
      } -> exec { 'create awslogs logrotation temp dir':
        command => 'mkdir -p /tmp/shinesolutions/logrotate/awslogs',
        path    => $exec_path,
        before  => [
                      Exec['Enable awslogs logrotation'],
                      Exec['Disable awslogs logrotation'],
                    ],
        onlyif  => 'ls /etc/logrotate.d/awslogs*'
      } -> exec { 'Disable awslogs logrotation':
        command => 'mv /etc/logrotate.d/awslogs* /tmp/shinesolutions/logrotate/awslogs/',
        path    => $exec_path,
        onlyif  => 'ls /etc/logrotate.d/awslogs*',
        require => Exec['create awslogs logrotation temp dir'],
        before  => [
                    Exec['Enable awslogs logrotation'],
                    Exec['Prevent awslogs service from restart'],
                    Exec['Stopping awslogs service to prevent it from accessing mounted FS']
                  ],
      } -> exec { 'Prevent awslogs service from restart':
        command => "systemctl disable --now --no-block ${$awslogs_service_name}",
        path    => $exec_path,
        require => [
                    Exec['Disable awslogs CronJobs'],
                    Exec['Disable awslogs logrotation'],
                  ],
        before  => [
                    Exec['Enable awslogs CronJobs'],
                    Exec['Enable awslogs logrotation'],
                    Exec["Attach volume from snapshot ID ${snapshotid}"]
                    ],
      } -> exec { 'Stopping awslogs service to prevent it from accessing mounted FS':
        command => "systemctl stop ${$awslogs_service_name}",
        path    => $exec_path,
        require => [
                    Exec['Disable awslogs CronJobs'],
                    Exec['Disable awslogs logrotation'],
                  ],
        before  => [
                    Exec['Enable awslogs CronJobs'],
                    Exec['Enable awslogs logrotation'],
                    Exec["Attach volume from snapshot ID ${snapshotid}"]
                    ],
      }
    }

    exec { "Attach volume from snapshot ID ${snapshotid}":
      command => "${base_dir}/aws-tools/snapshot_attach.py --device ${aem_repo_devices[0][device_name]} --device-alias ${aem_repo_devices[0][device_alias]} --volume-type ${volume_type} --snapshot-id ${snapshotid} -vvvv",
      timeout => $snapshot_attach_timeout,
      path    => $exec_path,
      before  => Exec['Sleep 15 seconds before allowing access the mounted FS']
    }

    exec { 'Sleep 15 seconds before allowing access the mounted FS':
      command => 'sleep 15',
      path    => $exec_path,
      require => Exec["Attach volume from snapshot ID ${snapshotid}"],
      before  => [
        Class['aem_curator::config_publish']
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

  # There is only a need to call the update_awslogs class
  # if awslogs is installed.
  if $awslogs_exists {
    class { 'update_awslogs':
      awslogs_service_name => $awslogs_service_name,
      config_file_path     => $awslogs_config_path,
      exec_path            => $exec_path,
      before               => Class['aem_curator::config_publish']
    }
  }
}

class update_awslogs (
  $config_file_path,
  $exec_path,
  $awslogs_service_name,
) {
  exec { 'Enable awslogs CronJobs':
    command => 'mv /tmp/shinesolutions/crons/awslogs/* /etc/cron.d/',
    path    => $exec_path,
    onlyif  => 'ls /tmp/shinesolutions/crons/awslogs/*',
    before  => Service[$awslogs_service_name]
  }

  exec { 'Enable awslogs logrotation':
    command => 'mv /tmp/shinesolutions/logrotate/awslogs/* /etc/logrotate.d/',
    path    => $exec_path,
    onlyif  => 'ls /tmp/shinesolutions/logrotate/awslogs/*',
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
