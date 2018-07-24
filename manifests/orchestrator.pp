File {
  backup => false,
}

class orchestrator (
  $base_dir,
  $tmp_dir,
  $aem_tools_env_path       = '$PATH:/opt/puppetlabs/puppet/bin',
  $stack_manager_stack_name = undef,
  $data_bucket_name         = $::data_bucket_name,
  $stack_prefix             = $::stack_prefix,
  $component                = $::component,
) {

  Archive {
    checksum_verify => false,
  }

  include aem_orchestrator

  ##############################################################################
  # Stack offline snapshot without compaction
  ##############################################################################

  file { "${base_dir}/aem-tools/stack-offline-snapshot-full-set-message.json":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/stack-offline-snapshot-full-set-message.json.epp", { 'stack_prefix' => "${stack_prefix}"}),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/stack-offline-snapshot.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/stack-offline-snapshot-full-set.sh.epp", {
      'base_dir'                 => $base_dir,
      'stack_manager_stack_name' => $stack_manager_stack_name,
    }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

  ##############################################################################
  # Stack-level offline snapshot with compaction
  ##############################################################################

  file { "${base_dir}/aem-tools/stack-offline-compaction-snapshot-full-set-message.json":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/stack-offline-compaction-snapshot-full-set-message.json.epp", { 'stack_prefix' => "${stack_prefix}"}),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/stack-offline-compaction-snapshot.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/stack-offline-compaction-snapshot-full-set.sh.epp", {
      'base_dir'                 => $base_dir,
      'stack_manager_stack_name' => $stack_manager_stack_name,
    }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

  ##############################################################################
  # Schedule jobs for offline snapshot & offline compaction snapshot
  ##############################################################################

  file { "${base_dir}/aem-tools/schedule-offline-snapshots.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/schedule-offline-snapshots.sh.epp",
    {
      'aem_tools_env_path' => $aem_tools_env_path,
      'base_dir'           => $base_dir,
      'data_bucket_name'   => $data_bucket_name,
      'stack_prefix'       => $stack_prefix,
      'tmp_dir'            => $tmp_dir
      }
    ),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

  ##############################################################################
  # AEM Readiness test
  ##############################################################################

  file { "${base_dir}/aem-tools/test-readiness.sh":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/test-readiness.sh.epp",
      {
        'aem_tools_env_path' => $aem_tools_env_path,
        'base_dir'           => $base_dir,
      }
    ),
  }

  ##############################################################################
  # Update /etc/awslogs/awslogs.conf
  # to contain stack_prefix and component name
  ##############################################################################

  class { 'update_awslogs': }

  ##############################################################################
  # Configure logrotation
  ##############################################################################

  class { 'aem_curator::config_logrotate': }

}

class update_awslogs (
  $old_awslogs_content = file('/etc/awslogs/awslogs.conf'),
) {
  service { 'awslogs':
    ensure => 'running',
    enable => true
  }
  $mod_awslogs_content = regsubst($old_awslogs_content, '^log_group_name = ', "log_group_name = ${$stack_prefix}", 'G' )
  $new_awslogs_content = regsubst($mod_awslogs_content, '^log_stream_name = ', "log_stream_name = ${$component}/", 'G' )
  file { 'Update file /etc/awslogs/awslogs.conf':
    ensure  => file,
    content => $new_awslogs_content,
    path    => '/etc/awslogs/awslogs.conf',
    notify  => Service['awslogs'],
  }
}

include orchestrator
