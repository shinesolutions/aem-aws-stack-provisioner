File {
  backup => false,
}

class action_scheduled_jobs (
  $base_dir,
  $env_path                            = $::cron_env_path,
  $https_proxy                         = $::cron_https_proxy,
  $export_enable                       = false,
  $live_snapshot_enable                = false,
  $offline_compaction_snapshot_enable  = false,
  $offline_snapshot_enable             = false,
  $export_hour                         = '2',
  $export_minute                       = '0',
  $export_weekday                      = '0-7',
  $live_snapshot_hour                  = '*',
  $live_snapshot_minute                = '0',
  $live_snapshot_weekday               = '0-7',
  $offline_compaction_snapshot_hour    = '1',
  $offline_compaction_snapshot_minute  = '15',
  $offline_compaction_snapshot_weekday = '1',
  $offline_snapshot_hour               = '1',
  $offline_snapshot_minute             = '15',
  $offline_snapshot_weekday            = '2-7',
  $log_dir                             = '/var/log/shinesolutions',
) {

  if $offline_snapshot_enable == true {
    cron { 'stack-offline-snapshot':
      ensure      => present,
      command     => "${base_dir}/aem-tools/stack-offline-snapshot.sh >${log_dir}/cron-stack-offline-snapshot.log 2>&1",
      user        => 'root',
      hour        => $offline_snapshot_hour,
      minute      => $offline_snapshot_minute,
      weekday     => $offline_snapshot_weekday,
      environment => ["PATH=${env_path}", "https_proxy=\"${https_proxy}\""],
    }
  } else {
    cron { 'stack-offline-snapshot':
      ensure      => absent,
      command     => "${base_dir}/aem-tools/stack-offline-snapshot.sh >${log_dir}/cron-stack-offline-snapshot.log 2>&1",
      user        => 'root',
      environment => ["PATH=${env_path}", "https_proxy=\"${https_proxy}\""]
    }
  }

  if $offline_compaction_snapshot_enable == true {
    cron { 'stack-offline-compaction-snapshot':
      ensure      => present,
      command     => "${base_dir}/aem-tools/stack-offline-compaction-snapshot.sh >${log_dir}/cron-stack-offline-compaction-snapshot.log 2>&1",
      user        => 'root',
      hour        => $offline_compaction_snapshot_hour,
      minute      => $offline_compaction_snapshot_minute,
      weekday     => $offline_compaction_snapshot_weekday,
      environment => ["PATH=${env_path}", "https_proxy=\"${https_proxy}\""],
    }
  } else {
    cron { 'stack-offline-compaction-snapshot':
      ensure      => absent,
      command     => "${base_dir}/aem-tools/stack-offline-compaction-snapshot.sh >${log_dir}/cron-stack-offline-compaction-snapshot.log 2>&1",
      user        => 'root',
      environment => ["PATH=${env_path}", "https_proxy=\"${https_proxy}\""]
    }
  }

  if $live_snapshot_enable == true {
    cron { 'live-snapshot-backup':
      ensure      => present,
      command     => "${base_dir}/aem-tools/live-snapshot-backup.sh >>${log_dir}/cron-live-snapshot-backup.log 2>&1",
      user        => 'root',
      hour        => $live_snapshot_hour,
      minute      => $live_snapshot_minute,
      weekday     => $live_snapshot_weekday,
      environment => ["PATH=${env_path}", "https_proxy=\"${https_proxy}\""],
    }
  } else {
    cron { 'live-snapshot-backup':
    ensure      => absent,
    command     => "${base_dir}/aem-tools/live-snapshot-backup.sh >>${log_dir}/cron-live-snapshot-backup.log 2>&1",
    user        => 'root',
    environment => ["PATH=${env_path}", "https_proxy=\"${https_proxy}\""]
    }
  }

  if $export_enable == true {
    cron { 'export-backups':
      ensure      => present,
      command     => "${base_dir}/aem-tools/export-backups.sh export-backups-descriptor.json >>${log_dir}/cron-export-backups.log 2>&1",
      user        => 'root',
      hour        => $export_hour,
      minute      => $export_minute,
      weekday     => $export_weekday,
      environment => ["PATH=${env_path}", "https_proxy=\"${https_proxy}\""],
    }
  } else {
    cron { 'export-backups':
      ensure      => absent,
      command     => "${base_dir}/aem-tools/export-backups.sh export-backups-descriptor.json >>${log_dir}/cron-export-backups.log 2>&1",
      user        => 'root',
      environment => ["PATH=${env_path}", "https_proxy=\"${https_proxy}\""]
    }
  }
}

include action_scheduled_jobs
