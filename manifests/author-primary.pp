class author_primary (
  $base_dir,
  $tmp_dir,
  $puppet_conf_dir,
  $crx_quickstart_dir,
  $author_protocol,
  $author_port,
  $aem_repo_device,
  $credentials_file,
) {

  $credentials_hash = loadjson("${tmp_dir}/${credentials_file}")

  file { "${crx_quickstart_dir}/install/":
    ensure => directory,
    mode   => '0775',
    owner  => 'aem',
    group  => 'aem',
  } -> archive { "${crx_quickstart_dir}/install/aem-password-reset-content-${::aem_password_reset_version}.zip":
    ensure => present,
    source => "s3://${::data_bucket}/${::stackprefix}/aem-password-reset-content-${::aem_password_reset_version}.zip",
  } -> class { 'aem_resources::puppet_aem_resources_set_config':
    conf_dir => "${puppet_conf_dir}",
    protocol => "${author_protocol}",
    host     => 'localhost',
    port     => "${author_port}",
    debug    => true,
  } -> class { 'aem_resources::author_primary_set_config':
    crx_quickstart_dir => "${crx_quickstart_dir}",
  } -> service { 'aem-aem':
    ensure => 'running',
    enable => true,
  } -> aem_aem { 'Wait until login page is ready':
    ensure                     => login_page_is_ready,
    retries_max_tries          => 60,
    retries_base_sleep_seconds => 5,
    retries_max_sleep_seconds  => 5,
  } -> aem_bundle_alias { 'Start webdav bundle':
    ensure => started,
    name   => 'org.apache.sling.jcr.webdav',
  } -> aem_package { 'Remove password reset package':
    ensure  => absent,
    name    => 'aem-password-reset-content',
    group   => 'shinesolutions',
    version => $::aem_password_reset_version,
  } -> class { 'aem_resources::create_system_users':
    orchestrator_password => $credentials_hash['orchestrator'],
    replicator_password   => $credentials_hash['replicator'],
    deployer_password     => $credentials_hash['deployer'],
    exporter_password     => $credentials_hash['exporter'],
    importer_password     => $credentials_hash['importer'],
  } -> aem_bundle { 'Stop webdav bundle':
    ensure => stopped,
    name   => 'org.apache.sling.jcr.webdav',
  } -> aem_user { 'Change admin password':
    ensure       => password_changed,
    name         => 'admin',
    path         => '/home/users/d',
    old_password => 'admin',
    new_password => $credentials_hash['admin']
  }

  file { "${crx_quickstart_dir}/install/aem-password-reset-content-${::aem_password_reset_version}.zip":
    ensure => absent,
  }

  # Set up AEM tools
  file { "${base_dir}/aem-tools/":
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } -> file { "${base_dir}/aem-tools/deploy-artifact.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/deploy-artifact.sh.epp", { 'base_dir' => "${base_dir}" }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/deploy-artifacts.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/deploy-artifacts.sh.epp", { 'base_dir' => "${base_dir}" }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/export-backup.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/export-backup.sh.epp", { 'base_dir' => "${base_dir}" }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/import-backup.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/import-backup.sh.epp", { 'base_dir' => "${base_dir}" }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

  archive { "${base_dir}/aem-tools/oak-run-${::oak_run_version}.jar":
    ensure => present,
    source => "s3://${::data_bucket}/${::stackprefix}/oak-run-${::oak_run_version}.jar",
  } -> file { "${base_dir}/aem-tools/offline-compaction.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/offline-compaction.sh.epp", {
      'base_dir'           => "${base_dir}",
      'oak_run_version'    => "${::oak_run_version}",
      'crx_quickstart_dir' => $crx_quickstart_dir,
    }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> cron { 'weekly-offline-compaction':
    command => "${base_dir}/aem-tools/offline-compaction.sh >>/var/log/offline-compaction.log 2>&1",
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
  } -> cron { 'daily-export-backups':
    command     => "${base_dir}/aem-tools/export-backups.sh export-backups-descriptor.json >>/var/log/export-backups.log 2>&1",
    user        => 'root',
    hour        => 2,
    minute      => 0,
    environment => ["PATH=${::cron_env_path}", "https_proxy=\"${::cron_https_proxy}\""],
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
  } -> cron { 'hourly-live-snapshot-backup':
    command     => "${base_dir}/aem-tools/live-snapshot-backup.sh >>/var/log/live-snapshot-backup.log 2>&1",
    user        => 'root',
    hour        => '*',
    minute      => 0,
    environment => ["PATH=${::cron_env_path}", "https_proxy=\"${::cron_https_proxy}\""],
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

include author_primary
