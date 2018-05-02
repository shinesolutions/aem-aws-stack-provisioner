File {
  backup => false,
}

class publish (
  $base_dir,
  $exec_path,
  $aem_repo_devices,
  $aem_password_retrieval_command,
  $enable_hourly_live_snapshot_cron,
  $enable_daily_export_cron,
  $volume_type,
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
    exec { "Attach volume from snapshot ID ${snapshotid}":
      command => "${base_dir}/aws-tools/snapshot_attach.py --device ${aem_repo_devices[0][device_name]} --device-alias ${aem_repo_devices[0][device_alias]} --volume-type ${volume_type} --snapshot-id ${snapshotid} -vvvv",
      path    => $exec_path,
    }
  }

  class { 'aem_curator::config_aem_tools':
    aem_tools_env_path => $aem_tools_env_path
  } -> class { 'aem_curator::config_aem_deployer':
    aem_tools_env_path => $aem_tools_env_path
  } -> class { 'aem_curator::config_publish':
    publish_dispatcher_id   => $publish_dispatcher_id,
    publish_dispatcher_host => $publish_dispatcher_host,
  } -> class { 'aem_curator::config_collectd':
    component       => $component,
    collectd_prefix => "${stack_prefix}-${component}",
    ec2_id          => "${ec2_id}"
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

  if $enable_daily_export_cron {
    cron { 'daily-export-backups':
      command     => "${base_dir}/aem-tools/export-backups.sh export-backups-descriptor.json >>/var/log/export-backups.log 2>&1",
      user        => 'root',
      hour        => 2,
      minute      => 0,
      environment => ["PATH=${env_path}", "https_proxy=\"${https_proxy}\""],
      require     => File["${base_dir}/aem-tools/export-backups.sh"],
    }
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
        'aem_tools_env_path' => $aem_tools_env_path,
        'base_dir'           => $base_dir,
        'aem_repo_devices'   => $aem_repo_devices,
        'component'          => $component,
        'stack_prefix'       => $stack_prefix,
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
        'aem_tools_env_path' => $aem_tools_env_path,
        'base_dir'           => $base_dir,
        'aem_repo_devices'   => $aem_repo_devices,
        'component'          => $component,
        'stack_prefix'       => $stack_prefix,
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

}

include publish
