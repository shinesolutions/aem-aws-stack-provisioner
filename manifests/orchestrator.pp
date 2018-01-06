File {
  backup => false,
}

class orchestrator (
  $base_dir,
  $offline_snapshot_hour = 1,
  $offline_snapshot_minute = 15,
  $enable_weekly_offline_compaction_snapshot = true,
  $stack_prefix        = $::stack_prefix,
  $env_path            = $::cron_env_path,
  $https_proxy         = $::cron_https_proxy,
) {

  Archive {
    checksum_verify => false,
  }

  include aem_orchestrator

  class { 'aem_curator::config_aem_tools':
  }

  ##############################################################################
  # Stack offline snapshot without compaction
  ##############################################################################

  file { "${base_dir}/aem-tools/stack-offline-snapshot-message.json":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/stack-offline-snapshot-message.json.epp", { 'stack_prefix' => "${stack_prefix}"}),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    require => File["${base_dir}/aem-tools/"],
  } -> file { "${base_dir}/aem-tools/stack-offline-snapshot.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/stack-offline-snapshot.sh.epp", { 'sns_topic_arn' => "${::stack_manager_sns_topic_arn}",}),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

  # If weekly stack offline compaction snapshot is enabled, nightly stack offline
  # snapshot only runs from Tuesday to Sunday, leaving Monday for _both_ stack offline
  # snapshot and compaction (configured further down).
  # If it's not enabled, nightly stack offline snapshot runs every day of the week.
  if $enable_weekly_offline_compaction_snapshot {
    # Tuesday to Sunday
    cron { 'nightly-stack-offline-snapshot':
      command     => "cd ${base_dir}/aem-tools && ./stack-offline-snapshot.sh >/var/log/stack-offline-snapshot.log 2>&1",
      user        => 'root',
      hour        => $offline_snapshot_hour,
      minute      => $offline_snapshot_minute,
      weekday     => '2-7',
      environment => ["PATH=${env_path}", "https_proxy=\"${https_proxy}\""],
      require     => File["${base_dir}/aem-tools/stack-offline-snapshot.sh"],
    }
  }
  else {
    # Monday to Sunday
    cron { 'nightly-stack-offline-snapshot':
      command     => "cd ${base_dir}/aem-tools && ./stack-offline-snapshot.sh >/var/log/stack-offline-snapshot.log 2>&1",
      user        => 'root',
      hour        => $offline_snapshot_hour,
      minute      => $offline_snapshot_minute,
      weekday     => '1-7',
      environment => ["PATH=${env_path}", "https_proxy=\"${https_proxy}\""],
      require     => File["${base_dir}/aem-tools/stack-offline-snapshot.sh"],
    }
  }

  ##############################################################################
  # Stack-level offline snapshot with compaction
  ##############################################################################

  file { "${base_dir}/aem-tools/stack-offline-compaction-snapshot-message.json":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/stack-offline-compaction-snapshot-message.json.epp", { 'stack_prefix' => "${stack_prefix}"}),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    require => File["${base_dir}/aem-tools/"],
  } -> file { "${base_dir}/aem-tools/stack-offline-compaction-snapshot.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/stack-offline-compaction-snapshot.sh.epp", { 'sns_topic_arn' => "${::stack_manager_sns_topic_arn}",}),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

  # If weekly stack offline compaction snapshot is enabled, then set both stack
  # offline snapshot and compaction to run one day a week.
  if $enable_weekly_offline_compaction_snapshot {
    # Monday only
    cron { 'weekly-stack-offline-compaction-snapshot':
      command     => "cd ${base_dir}/aem-tools && ./stack-offline-compaction-snapshot.sh >/var/log/stack-offline-compaction-snapshot.log 2>&1",
      user        => 'root',
      hour        => $offline_snapshot_hour,
      minute      => $offline_snapshot_minute,
      weekday     => 1,
      environment => ["PATH=${env_path}", "https_proxy=\"${https_proxy}\""],
      require     => File["${base_dir}/aem-tools/stack-offline-compaction-snapshot.sh"],
    }
  }
}

include orchestrator
