class publish (
  $base_dir,
  $tmp_dir,
  $puppet_conf_dir,
  $publish_protocol,
  $publish_port,
  $aem_repo_device,
) {

  class { 'aem_resources::puppet_aem_resources_set_config':
    conf_dir => "${puppet_conf_dir}",
    protocol => "${publish_protocol}",
    host     => 'localhost',
    port     => "${publish_port}",
    debug    => true,
  } ->
  service { 'aem-aem':
    ensure => 'running',
    enable => true,
  } ->
  aem_aem { 'Wait until login page is ready':
    ensure                     => login_page_is_ready,
    retries_max_tries          => 60,
    retries_base_sleep_seconds => 5,
    retries_max_sleep_seconds  => 5,
  } ->
  aem_flush_agent { 'Create flush agent':
    ensure        => present,
    name          => "flushAgent-${::pairinstanceid}",
    run_mode      => 'publish',
    title         => "Flush agent for publish-dispatcher ${::pairinstanceid}",
    description   => "Flush agent for publish-dispatcher ${::pairinstanceid}",
    dest_base_url => "http://${::publishdispatcherhost}:80",
    log_level     => 'info',
    retry_delay   => 60000,
    force         => true,
  } ->
  aem_bundle { 'Stop webdav bundle':
    ensure => stopped,
    name   => 'org.apache.sling.jcr.webdav',
  }

  # Set up AEM tools
  file { "${base_dir}/aem-tools/":
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } ->
  file { "${base_dir}/aem-tools/deploy-artifact.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/deploy-artifact.sh.epp", { 'base_dir' => "${base_dir}" }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } ->
  file { "${base_dir}/aem-tools/deploy-artifacts.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/deploy-artifacts.sh.epp", { 'base_dir' => "${base_dir}" }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } ->
  file { "${base_dir}/aem-tools/export-backup.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/export-backup.sh.epp", { 'base_dir' => "${base_dir}" }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } ->
  file { "${base_dir}/aem-tools/import-backup.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/import-backup.sh.epp", { 'base_dir' => "${base_dir}" }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

  archive { "${base_dir}/aem-tools/oak-run-${::oak_run_version}.jar":
    ensure => present,
    source => "s3://${::data_bucket}/${::stackprefix}/oak-run-${::oak_run_version}.jar",
  } ->
  file { "${base_dir}/aem-tools/offline-compaction.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/offline-compaction.sh.epp", {
      'base_dir'           => "${base_dir}",
      'oak_run_version'    => "${::oak_run_version}",
      'crx_quickstart_dir' => '/opt/aem/publish/crx-quickstart',
    }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } ->
  cron { 'weekly-offline-compaction':
    command => "${base_dir}/aem-tools/offline-compaction.sh",
    user    => 'root',
    weekday => 2,
    hour    => 3,
    minute  => 0,
  }

  file { "${base_dir}/aem-tools/export-backups.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/export-backups.sh.epp", { 'base_dir' => "${base_dir}" }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } ->
  cron { 'daily-export-backups':
    command     => "${base_dir}/aem-tools/export-backups.sh export-backups-descriptor.json",
    user        => 'root',
    hour        => 2,
    minute      => 0,
    environment => 'PATH=/sbin:/bin:/usr/sbin:/usr/bin:/opt/puppetlabs/bin',
    require     => File["${base_dir}/aem-tools/export-backups.sh"],
  }

  file { "${base_dir}/aem-tools/live-snapshot-backup.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/live-snapshot-backup.sh.epp", {
      'base_dir'        => "${base_dir}",
      'aem_repo_device' => "${aem_repo_device}",
      'component'       => "${::component}",
      'stack_prefix'    => "${::stackprefix}",
    }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } ->
  cron { 'hourly-live-snapshot-backup':
    command     => "${base_dir}/aem-tools/live-snapshot-backup.sh",
    user        => 'root',
    hour        => '*',
    minute      => 0,
    environment => 'PATH=/sbin:/bin:/usr/sbin:/usr/bin:/opt/puppetlabs/bin',
  }

  file { "${base_dir}/aem-tools/offline-snapshot-backup.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/offline-snapshot-backup.sh.epp", {
      'base_dir'        => "${base_dir}",
      'aem_repo_device' => "${aem_repo_device}",
      'component'       => "${::component}",
      'stack_prefix'    => "${::stackprefix}",
    }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

}

include publish
