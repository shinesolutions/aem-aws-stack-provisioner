File {
  backup => false,
}

class author_standby (
  $base_dir,
  $aem_repo_devices,
  $tmp_dir,
  $awslogs_config_path,
  $author_primary_host        = $::authorprimaryhost,
  $component                  = $::component,
  $stack_prefix               = $::stack_prefix,
  $aem_tools_env_path         = '$PATH:/opt/puppetlabs/puppet/bin',
  $ec2_id                     = $::ec2_metadata['instance-id'],
) {

  # A simple check for checking if the awslogs(Cloudwatch Agent)
  # configuration file exists or not.
  #
  # We are using this to determine if the cloudwatch agent installation
  # was enabled or disabled while baking the AMIs with packer-aem
  #
  # More information about the find_file function can be found here:
  # https://puppet.com/docs/puppet/5.5/function.html#findfile
  #
  $awslogs_exists = find_file($awslogs_config_path)

  class { 'aem_curator::config_aem_tools':
    aem_tools_env_path => $aem_tools_env_path
  } -> class { 'aem_curator::config_aem_deployer':
    aem_tools_env_path => $aem_tools_env_path
  } -> class { 'aem_curator::config_author_standby':
    author_primary_host => $author_primary_host,
  } -> class { 'aem_curator::config_logrotate':
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
        'aws_region'         => $aws_region,
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
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/offline-snapshot-backup-full-set.sh.epp",
      {
        'aem_tools_env_path' => $aem_tools_env_path,
        'base_dir'           => $base_dir,
        'aem_repo_devices'   => $aem_repo_devices,
        'component'          => $component,
        'stack_prefix'       => $stack_prefix,
        'aws_region'         => $aws_region,
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
  # Schedule jobs for live snapshot, offline snapshot & offline compaction snapshot
  ##############################################################################

  file { "${base_dir}/aem-tools/schedule-snapshots.sh":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/schedule-snapshots.sh.epp",
    {
      'aem_tools_env_path' => $aem_tools_env_path,
      'base_dir'           => $base_dir,
      'data_bucket_name'   => $data_bucket_name,
      'stack_prefix'       => $stack_prefix,
      'tmp_dir'            => $tmp_dir,
      'aws_region'         => $aws_region,
      }
    ),
  }

  ##############################################################################
  # Update AWS Logs proxy settings file
  # to contain stack_prefix and component name
  ##############################################################################

  # There is only a need to call the update_awslogs class
  # if awslogs is installed.
  if $awslogs_exists {
    class { 'update_awslogs':
      config_file_path => $awslogs_config_path
    }
  }

  exec { 'Resize data volume size':
    command => "resize2fs ${aem_repo_devices[0][device_name]}",
    path    => ['/bin', '/usr/local/bin', '/usr/bin', '/usr/sbin'],
  }
}

class update_awslogs (
  $config_file_path,
  $awslogs_service_name = lookup('common::awslogs_service_name')
) {
  $old_awslogs_content = file($config_file_path)
  $mod_awslogs_content = regsubst($old_awslogs_content, '^log_group_name = ', "log_group_name = ${$stack_prefix}", 'G' )
  $new_awslogs_content = regsubst($mod_awslogs_content, '^log_stream_name = ', "log_stream_name = ${$component}/", 'G' )
  file { 'Update AWS Logs proxy settings file':
    ensure  => file,
    content => $new_awslogs_content,
    path    => $config_file_path,
    before  => Service[$awslogs_service_name],
  } -> service { $awslogs_service_name:
    ensure  => 'running',
    enable  => true,
    require => File['Update AWS Logs proxy settings file'],
  }
}

include author_standby
