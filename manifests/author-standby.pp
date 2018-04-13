File {
  backup => false,
}

class author_standby (
  $base_dir,
  $aem_repo_devices,
  $enable_hourly_live_snapshot_cron,
  $author_primary_host = $::authorprimaryhost,
  $component           = $::component,
  $stack_prefix        = $::stack_prefix,
  $env_path            = $::cron_env_path,
  $aem_tools_env_path  = '$PATH:/opt/puppetlabs/puppet/bin',
  $https_proxy         = $::cron_https_proxy,
  $ec2_id              = $::ec2_metadata['instance-id'],
) {

  class { 'aem_curator::config_aem_tools':
    aem_tools_env_path => $aem_tools_env_path
  } -> class { 'aem_curator::config_aem_deployer':
    aem_tools_env_path => $aem_tools_env_path
  } -> class { 'aem_curator::config_author_standby':
    author_primary_host => $author_primary_host,
  } -> class { 'aem_curator::config_collectd':
    component       => $component,
    collectd_prefix => "${stack_prefix}-${component}",
    ec2_id          => "${ec2_id}"
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
  # Promote Author Standby to Author Primary
  ##############################################################################

  file { "${base_dir}/aws-tools/promote-author-standby-to-primary.sh":
    ensure  => file,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      "${base_dir}/aem-aws-stack-provisioner/templates/aws-tools/promote-author-standby-to-primary.sh.epp",
      {
        'base_dir' => $base_dir,
      }
    ),
  }
}

include author_standby
