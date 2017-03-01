class promote_author_standby_to_primary (
  $base_dir,
  $tmp_dir,
) {

  exec { 'service aem-aem stop':
    cwd  => "${tmp_dir}",
    path => ['/usr/bin', '/usr/sbin'],
  } ->
  exec { 'set-component.sh author-primary':
    cwd  => "${tmp_dir}",
    path => ["${base_dir}/aws-tools", '/usr/bin', '/opt/puppetlabs/bin/'],
  } ->
  class { 'aem_resources::author_primary_set_config':
    crx_quickstart_dir => '/opt/aem/author/crx-quickstart',
  } ->
  service { 'aem-aem':
    ensure => 'running',
    enable => true,
  } ->
  aem_aem { 'Wait until login page is ready':
    ensure                     => login_page_is_ready,
    retries_max_tries          => 30,
    retries_base_sleep_seconds => 5,
    retries_max_sleep_seconds  => 5,
  }

  cron { 'weekly-offline-compaction':
    command => "${base_dir}/aem-tools/offline-compaction.sh",
    user    => 'root',
    weekday => 2,
    hour    => 3,
    minute  => 0,
  }

  cron { 'daily-export-backups':
    command => "${base_dir}/aem-tools/export-backups.sh export-backups-descriptor.json",
    user    => 'root',
    hour    => 2,
    minute  => 0,
  }

  cron { 'hourly-live-snapshot-backup':
    command => "${base_dir}/aem-tools/live-snapshot-backup.sh",
    user    => 'root',
    hour    => '*',
    minute  => 0,
  }

}

include promote_author_standby_to_primary
