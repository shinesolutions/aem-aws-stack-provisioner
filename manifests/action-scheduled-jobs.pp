File {
  backup => false,
}

class action_scheduled_jobs (
  $base_dir,
  $env_path                            = $::cron_env_path,
  $http_proxy                          = $::cron_http_proxy,
  $https_proxy                         = $::cron_https_proxy,
  $no_proxy                            = $::cron_no_proxy,
  $cloudwatch_s3_stream_enable         = false,
  $export_enable                       = false,
  $live_snapshot_enable                = false,
  $offline_compaction_snapshot_enable  = false,
  $offline_snapshot_enable             = false,
  $content_health_check_enable         = false,
  $cloudwatch_s3_stream_weekday        = '*',
  $cloudwatch_s3_stream_hour           = '*',
  $cloudwatch_s3_stream_minute         = '30',
  $cloudwatch_log_subscription_arn     = '',
  $content_health_check_weekday        = '*',
  $content_health_check_hour           = '*',
  $content_health_check_minute         = '*',
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
  $stack_prefix                        = $::stack_prefix,
) {

  # This dummy job is a placeholder just to import proxy environment variables once off
  # all jobs after this do not need to set proxies unless overriding is required
  cron { 'set-proxies':
    ensure      => present,
    command     => '/bin/true # dummy job just to import proxy environment variables once',
    user        => 'root',
    hour        => 23,
    minute      => 59,
    month       => 12,
    monthday    => 30,
    weekday     => 0,
    environment => ["PATH=${env_path}", "http_proxy=\"${http_proxy}\"", "https_proxy=\"${https_proxy}\"", "no_proxy=\"${no_proxy}\""]
  }

  if $offline_snapshot_enable == true {
    cron { 'stack-offline-snapshot':
      ensure  => present,
      command => "${base_dir}/aem-tools/stack-offline-snapshot.sh >>${log_dir}/cron-stack-offline-snapshot.log 2>&1",
      user    => 'root',
      hour    => $offline_snapshot_hour,
      minute  => $offline_snapshot_minute,
      weekday => $offline_snapshot_weekday
    }
  } else {
    cron { 'stack-offline-snapshot':
      ensure  => absent,
      command => "${base_dir}/aem-tools/stack-offline-snapshot.sh >>${log_dir}/cron-stack-offline-snapshot.log 2>&1",
      user    => 'root'
    }
  }

  if $offline_compaction_snapshot_enable == true {
    cron { 'stack-offline-compaction-snapshot':
      ensure  => present,
      command => "${base_dir}/aem-tools/stack-offline-compaction-snapshot.sh >>${log_dir}/cron-stack-offline-compaction-snapshot.log 2>&1",
      user    => 'root',
      hour    => $offline_compaction_snapshot_hour,
      minute  => $offline_compaction_snapshot_minute,
      weekday => $offline_compaction_snapshot_weekday
    }
  } else {
    cron { 'stack-offline-compaction-snapshot':
      ensure  => absent,
      command => "${base_dir}/aem-tools/stack-offline-compaction-snapshot.sh >>${log_dir}/cron-stack-offline-compaction-snapshot.log 2>&1",
      user    => 'root'
    }
  }

  if $live_snapshot_enable == true {
    cron { 'live-snapshot-backup':
      ensure  => present,
      command => "${base_dir}/aem-tools/live-snapshot-backup.sh >>${log_dir}/cron-live-snapshot-backup.log 2>&1",
      user    => 'root',
      hour    => $live_snapshot_hour,
      minute  => $live_snapshot_minute,
      weekday => $live_snapshot_weekday
    }
  } else {
    cron { 'live-snapshot-backup':
    ensure  => absent,
    command => "${base_dir}/aem-tools/live-snapshot-backup.sh >>${log_dir}/cron-live-snapshot-backup.log 2>&1",
    user    => 'root'
    }
  }

  if $export_enable == true {
    cron { 'export-backups':
      ensure  => present,
      command => "${base_dir}/aem-tools/export-backups.sh export-backups-descriptor.json >>${log_dir}/cron-export-backups.log 2>&1",
      user    => 'root',
      hour    => $export_hour,
      minute  => $export_minute,
      weekday => $export_weekday
    }
  } else {
    cron { 'export-backups':
      ensure  => absent,
      command => "${base_dir}/aem-tools/export-backups.sh export-backups-descriptor.json >>${log_dir}/cron-export-backups.log 2>&1",
      user    => 'root'
    }
  }

  if $content_health_check_enable == true {
    cron { 'content-health-check':
      ensure  => present,
      command => "${base_dir}/aem-tools/content-healthcheck.py >>${log_dir}/cron-content-health-check.log 2>&1",
      user    => 'root',
      hour    => $content_health_check_hour,
      minute  => $content_health_check_minute,
      weekday => $content_health_check_weekday
    }
  } else {
    cron { 'content-health-check':
      ensure  => absent,
      command => "${base_dir}/aem-tools/content-healthcheck.py >>${log_dir}/cron-content-health-check.log 2>&1",
      user    => 'root'
    }
  }

  # CronJob for subscribing Stacks Cloudwatch logs to Lambda
  if $cloudwatch_s3_stream_enable == true {
    cron { 'clouddwatch-s3-stream':
      ensure  => present,
      command => "${base_dir}/aws-tools/cloudwatch-s3-stream.sh ${stack_prefix} ${cloudwatch_log_subscription_arn} >>${log_dir}/cron-clouddwatch-log-s3-stream.log 2>&1",
      user    => 'root',
      hour    => $cloudwatch_s3_stream_hour,
      minute  => $cloudwatch_s3_stream_minute,
      weekday => $cloudwatch_s3_stream_weekday
    }
  } else {
    cron { 'clouddwatch-s3-stream':
      ensure  => absent,
      command => "${base_dir}/aws-tools/cloudwatch-s3-stream.sh ${stack_prefix} ${cloudwatch_log_subscription_arn} >>${log_dir}/cron-clouddwatch-log-s3-stream.log 2>&1",
      user    => 'root'
    }
  }
}

include action_scheduled_jobs
