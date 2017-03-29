class promote_author_standby_to_primary (
  $base_dir,
  $tmp_dir
) {

  exec { 'service aem-aem stop':
    cwd  => "${tmp_dir}",
    path => ['/usr/bin', '/usr/sbin'],
  } -> exec { 'set-component.sh author-primary':
    cwd  => "${tmp_dir}",
    path => ["${base_dir}/aws-tools", '/usr/bin', '/opt/puppetlabs/bin/'],
  } -> class { 'aem_resources::author_primary_set_config':
    crx_quickstart_dir => '/opt/aem/author/crx-quickstart',
  } -> service { 'aem-aem':
    ensure => 'running',
    enable => true,
  } -> aem_aem { 'Wait until login page is ready':
    ensure                     => login_page_is_ready,
    retries_max_tries          => 30,
    retries_base_sleep_seconds => 5,
    retries_max_sleep_seconds  => 5,
  }

  cron { 'weekly-offline-compaction':
    command => "${base_dir}/aem-tools/offline-compaction.sh >>/var/log/offline-compaction.log 2>&1",
    user    => 'root',
    weekday => 2,
    hour    => 3,
    minute  => 0,
  }

  cron { 'daily-export-backups':
    command     => "${base_dir}/aem-tools/export-backups.sh export-backups-descriptor.json >>/var/log/export-backups.log 2>&1",
    user        => 'root',
    hour        => 2,
    minute      => 0,
    environment => ["PATH=${::cron_env_path}", "https_proxy=\"${::cron_https_proxy}\""],
  }

  cron { 'hourly-live-snapshot-backup':
    command     => "${base_dir}/aem-tools/live-snapshot-backup.sh >>/var/log/live-snapshot-backup.log 2>&1",
    user        => 'root',
    hour        => '*',
    minute      => 0,
    environment => ["PATH=${::cron_env_path}", "https_proxy=\"${::cron_https_proxy}\""],
  }

}

include promote_author_standby_to_primary
