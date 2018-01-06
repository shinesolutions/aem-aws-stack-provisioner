File {
  backup => false,
}

class publish (
  $base_dir,
  $aem_repo_device,
  $publish_dispatcher_id   = $::pairinstanceid,
  $publish_dispatcher_host = $::publishdispatcherhost,
  $stack_prefix            = $::stack_prefix,
  $component               = $::component,
  $env_path                = $::cron_env_path,
  $https_proxy             = $::cron_https_proxy,
) {

  class { 'aem_curator::config_aem_tools':
  } -> class { 'aem_curator::config_publish':
    publish_dispatcher_id   => $publish_dispatcher_id,
    publish_dispatcher_host => $publish_dispatcher_host,
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
        'base_dir'        => $base_dir,
        'aem_repo_device' => $aem_repo_device,
        'component'       => $component,
        'stack_prefix'    => $stack_prefix,
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
        'base_dir'        => $base_dir,
        'aem_repo_device' => $aem_repo_device,
        'component'       => $component,
        'stack_prefix'    => $stack_prefix,
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
