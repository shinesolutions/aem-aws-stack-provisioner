File {
  backup => false,
}

class orchestrator (
  $base_dir
) {
  Archive {
    checksum_verify => false,
  }
  include aem_orchestrator

  file { "${base_dir}/aem-tools/":
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  }

  # daily (except sunday) offline-snapshot
  file { "${base_dir}/aem-tools/stack-offline-snapshot-message.json":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/stack-offline-snapshot-message.json.epp", { 'stack_prefix' => "${::stackprefix}"}),
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
  } -> cron { 'nightly-stack-offline-snapshot':
    command     => "cd ${base_dir}/aem-tools && ./stack-offline-snapshot.sh >/var/log/stack-offline-snapshot.log 2>&1",
    user        => 'root',
    hour        => 1,
    minute      => 15,
    weekday     => [1-6],
    environment => ["PATH=${::cron_env_path}", "https_proxy=\"${::cron_https_proxy}\""],
  }

  # weekly offline-compaction-snapshot
  file { "${base_dir}/aem-tools/stack-offline-compaction-snapshot-message.json":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/stack-offline-compaction-snapshot-message.json.epp", { 'stack_prefix' => "${::stackprefix}"}),
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
  } -> cron { 'weekly-stack-offline-compaction-snapshot':
    command     => "cd ${base_dir}/aem-tools && ./stack-offline-compaction-snapshot.sh >/var/log/stack-offline-compaction-snapshot.log 2>&1",
    user        => 'root',
    hour        => 6,
    minute      => 15,
    weekday     => 0,
    environment => ["PATH=${::cron_env_path}", "https_proxy=\"${::cron_https_proxy}\""],
  }

}

include orchestrator
