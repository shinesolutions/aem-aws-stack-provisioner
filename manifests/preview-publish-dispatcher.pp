File {
  backup => false,
}

class preview_publish_dispatcher (
  $base_dir,
  $docroot_dir,
  $tmp_dir,
  $aws_region,
  $awslogs_config_path,
  $dispatcher_data_devices,
  $allowed_client             = $::preview_publish_dispatcher_allowed_client,
  $preview_publish_host       = $::previewpublishhost,
  $component                  = $::component,
  $stack_prefix               = $::stack_prefix,
  $stack_name                 = $facts['aws:cloudformation:stack-name'],
  $pair_instance_id           = $::pairinstanceid,
  $data_bucket_name           = $::data_bucket_name,
  $env_path                   = $::cron_env_path,
  $http_proxy                 = $::cron_http_proxy,
  $https_proxy                = $::cron_https_proxy,
  $no_proxy                   = $::cron_no_proxy,
  $exec_path                  = ['/bin', '/usr/local/bin', '/usr/bin'],
  $aem_tools_env_path         = '$PATH:/opt/puppetlabs/puppet/bin',
  $log_dir                    = '/var/log/shinesolutions',
  $deploy_timeout             = 900,
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

  class { 'aem_curator::config_aem_tools_dispatcher':
    aem_tools_env_path => $aem_tools_env_path
  } -> class { 'aem_curator::config_aem_deployer':
    aem_tools_env_path => $aem_tools_env_path
  } -> class { 'aem_curator::config_publish_dispatcher':
    allowed_client       => $allowed_client,
    publish_host         => $preview_publish_host,
    docroot_dir          => $docroot_dir,
  } -> class { 'aem_curator::config_logrotate':
  } -> exec { 'Deploy Preview-Publish-Dispatcher artifacts':
    path        => $exec_path,
    environment => ["https_proxy=${https_proxy}"],
    cwd         => $tmp_dir,
    timeout     => $deploy_timeout,
    command     => "${base_dir}/aem-tools/deploy-artifacts.sh deploy-artifacts-descriptor.json >>${log_dir}/puppet-deploy-artifacts-init.log 2>&1",
    onlyif      => "test `aws s3 ls s3://${data_bucket_name}/${stack_prefix}/deploy-artifacts-descriptor.json | wc -l` -eq 1",
  }

  ##############################################################################
  # Content health check
  ##############################################################################

  file { "${base_dir}/aem-tools/content-healthcheck.py":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/content-healthcheck.py.epp",
      {
        'tmp_dir'          => $tmp_dir,
        'stack_prefix'     => $stack_prefix,
        'data_bucket_name' => $data_bucket_name,
        'aws_region'       => $aws_region,
        'pair_instance_id' => $pair_instance_id,
        'stack_name'       => $stack_name,
        'publish_host'     => $preview_publish_host,
      }
    )
  }

  ##############################################################################
  # Enter and exit standby in AutoScalingGroup
  ##############################################################################

  file { "${base_dir}/aem-tools/enter-standby.sh":
    ensure => present,
    source => "file://${base_dir}/aem-aws-stack-provisioner/files/aem-tools/enter-standby.sh",
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } -> file { "${base_dir}/aem-tools/exit-standby.sh":
    ensure => present,
    source => "file://${base_dir}/aem-aws-stack-provisioner/files/aem-tools/exit-standby.sh",
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
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

  exec { 'Resize data volume size of dispatcher':
    command => "resize2fs ${dispatcher_data_devices[0][device_name]}",
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

include preview_publish_dispatcher
