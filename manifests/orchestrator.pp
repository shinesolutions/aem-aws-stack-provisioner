File {
  backup => false,
}

class orchestrator (
  $base_dir,
  $tmp_dir,
  $awslogs_config_path,
  $aem_tools_env_path          = '$PATH:/opt/puppetlabs/puppet/bin',
  $stack_manager_stack_name    = undef,
  $data_bucket_name            = $::data_bucket_name,
  $stack_prefix                = $::stack_prefix,
  $component                   = $::component,
  $enable_cloudwatch_s3_stream = false,
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
      'aws_region'               => $aws_region,
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
      'aws_region'               => $aws_region,
    }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

  ##############################################################################
  # Schedule jobs for live snapshot, offline snapshot & offline compaction snapshot
  ##############################################################################

  file { "${base_dir}/aem-tools/schedule-snapshots.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/schedule-snapshots.sh.epp",
    {
      'aem_tools_env_path' => $aem_tools_env_path,
      'base_dir'           => $base_dir,
      'data_bucket_name'   => $data_bucket_name,
      'stack_prefix'       => $stack_prefix,
      'tmp_dir'            => $tmp_dir,
      'aws_region'         => $aws_region,
      }
    ),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

  ##############################################################################
  # Cloudwatch to S3 stream shell script
  ##############################################################################
  if $enable_cloudwatch_s3_stream {
    file { "${base_dir}/aws-tools/cloudwatch-s3-stream.sh":
      ensure  => present,
      content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aws-tools/cloudwatch-s3-stream.sh.epp",
      {
        'aem_tools_env_path' => $aem_tools_env_path,
        'base_dir'           => $base_dir,
        }
      ),
      mode    => '0750',
      owner   => 'root',
      group   => 'root',
    }

    ##############################################################################
    # Cloudwatch to S3 stream python script
    ##############################################################################
    file { "${base_dir}/aws-tools/cloudwatch_logs_subscription.py":
      ensure => present,
      source => "file://${base_dir}/aem-aws-stack-provisioner/files/aws-tools/cloudwatch_logs_subscription.py",
      mode   => '0750',
      owner  => 'root',
      group  => 'root',
    }
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

  ##############################################################################
  # Configure logrotation
  ##############################################################################

  class { 'aem_curator::config_logrotate': }

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

include orchestrator
