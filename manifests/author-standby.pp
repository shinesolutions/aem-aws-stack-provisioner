File {
  backup => false,
}

class author_standby (
  $base_dir,
  $aem_repo_devices,
  $author_primary_host        = $::authorprimaryhost,
  $component                  = $::component,
  $stack_prefix               = $::stack_prefix,
  $aem_tools_env_path         = '$PATH:/opt/puppetlabs/puppet/bin',
  $ec2_id                     = $::ec2_metadata['instance-id'],
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
  ##############################################################################
  # Update /etc/awslogs/awslogs.conf
  # to contain stack_prefix and component name
  ##############################################################################

  class { 'update_awslogs': }
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

include author_standby
