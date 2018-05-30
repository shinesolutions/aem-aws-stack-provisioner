File {
  backup => false,
}

class publish_dispatcher (
  $base_dir,
  $docroot_dir,
  $tmp_dir,
  $allowed_client             = $::publish_dispatcher_allowed_client,
  $publish_host               = $::publishhost,
  $component                  = $::component,
  $stack_prefix               = $::stack_prefix,
  $data_bucket_name           = $::data_bucket_name,
  $env_path                   = $::cron_env_path,
  $https_proxy                = $::cron_https_proxy,
  $enable_content_healthcheck = true,
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

  if $enable_content_healthcheck {
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
        }
      ),
    } -> cron { 'every-minute-content-healthcheck':
      command     => "${base_dir}/aem-tools/content-healthcheck.py",
      user        => 'root',
      minute      => '*',
      environment => ["PATH=${env_path}", "https_proxy=\"${https_proxy}\""],
    }
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

include publish_dispatcher
