File {
  backup => false,
}

class publish_dispatcher (
  $base_dir,
  $docroot_dir,
  $tmp_dir,
  $aws_region,
  $awslogs_config_path,
  $allowed_client             = $::publish_dispatcher_allowed_client,
  $publish_host               = $::publishhost,
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
) {

  class { 'aem_curator::config_aem_tools_dispatcher':
    aem_tools_env_path => $aem_tools_env_path
  } -> class { 'aem_curator::config_aem_deployer':
    aem_tools_env_path => $aem_tools_env_path
  } -> class { 'aem_curator::config_publish_dispatcher':
    allowed_client => $allowed_client,
    publish_host   => $publish_host,
    docroot_dir    => $docroot_dir,
  } -> class { 'aem_curator::config_logrotate':
  } -> exec { 'Deploy Publish-Dispatcher artifacts':
    path        => $exec_path,
    environment => ["https_proxy=${https_proxy}"],
    cwd         => $tmp_dir,
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
        'publish_host'     => $publishhost,
      }
    ),
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

  class { 'update_awslogs':
    config_file_path => $awslogs_config_path
  }
}

class update_awslogs (
  $config_file_path,
  $awslogs_service_name,
) {
  service { $awslogs_service_name:
    ensure => 'running',
    enable => true
  }
  $old_awslogs_content = file($config_file_path)
  $mod_awslogs_content = regsubst($old_awslogs_content, '^log_group_name = ', "log_group_name = ${$stack_prefix}", 'G' )
  $new_awslogs_content = regsubst($mod_awslogs_content, '^log_stream_name = ', "log_stream_name = ${$component}/", 'G' )
  file { 'Update AWS Logs proxy settings file':
    ensure  => file,
    content => $new_awslogs_content,
    path    => $config_file_path,
    notify  => Service[$awslogs_service_name],
  }
}

include publish_dispatcher
