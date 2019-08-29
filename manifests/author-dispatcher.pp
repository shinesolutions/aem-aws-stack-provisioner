File {
  backup => false,
}

class author_dispatcher (
  $base_dir,
  $docroot_dir,
  $awslogs_config_path,
  $tmp_dir,
  $author_host        = $::authorhost,
  $component          = $::component,
  $stack_prefix       = $::stack_prefix,
  $data_bucket_name   = $::data_bucket_name,
  $exec_path          = ['/bin', '/usr/local/bin', '/usr/bin'],
  $aem_tools_env_path = '$PATH:/opt/puppetlabs/puppet/bin',
  $https_proxy        = $::cron_https_proxy,
  $log_dir            = '/var/log/shinesolutions',
  $deploy_timeout     = 900,
  $ssh_public_keys,
  $aws_user = 'ec2-user',
) {

  $ssh_public_keys.each | String $name, Hash $ssh_details| {
    $ssh_public_key      = $ssh_details['public_key']
    $ssh_public_key_type = $ssh_details['public_key_type']

      notify{"ssh details: ${ssh_public_key}":}

    ssh_authorized_key { "Adding public key for user ${name} to authorized_keys":
      ensure   => present,
      user     => $aws_user,
      provider => 'parsed',
      name     => $name,
      key      => $ssh_public_key,
      type     => $ssh_public_key_type,
    }
  }
  class { 'aem_curator::config_aem_tools_dispatcher':
    aem_tools_env_path => $aem_tools_env_path
  } -> class { 'aem_curator::config_aem_deployer':
    aem_tools_env_path => $aem_tools_env_path
  } -> class { 'aem_curator::config_author_dispatcher':
    author_host => $author_host,
    docroot_dir => $docroot_dir,
  } -> class { 'aem_curator::config_logrotate':
  } -> exec { 'Deploy Author-Dispatcher artifacts':
    path        => $exec_path,
    environment => ["https_proxy=${https_proxy}"],
    cwd         => $tmp_dir,
    timeout     => $deploy_timeout,
    command     => "${base_dir}/aem-tools/deploy-artifacts.sh deploy-artifacts-descriptor.json >>${log_dir}/puppet-deploy-artifacts-init.log 2>&1",
    onlyif      => "test `aws s3 ls s3://${data_bucket_name}/${stack_prefix}/deploy-artifacts-descriptor.json | wc -l` -eq 1",
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
  $awslogs_service_name = lookup('common::awslogs_service_name')
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

include author_dispatcher
