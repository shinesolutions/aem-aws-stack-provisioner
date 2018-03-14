File {
  backup => false,
}

class publish_dispatcher (
  $base_dir,
  $allowed_client = $::publish_dispatcher_allowed_client,
  $docroot_dir    = lookup('common::docroot_dir'),
  $publish_host   = $::publishhost,
  $stack_prefix   = $::stack_prefix,
  $data_bucket    = $::data_bucket,
  $env_path       = $::cron_env_path,
  $https_proxy    = $::cron_https_proxy,
) {

  file { "${base_dir}/aem-tools/":
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } class { 'aem_curator::config_aem_tools_dispatcher':
  } -> class { 'aem_curator::config_aem_deployer':
  } -> class { 'aem_curator::config_publish_dispatcher':
    allowed_client => $allowed_client,
    publish_host   => $publish_host,
    docroot_dir    => $docroot_dir,
  }

  file { "${base_dir}/aem-tools/content-healthcheck.py":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/content-healthcheck.py.epp",
      {
        'tmp_dir'      => $tmp_dir,
        'stack_prefix' => $stack_prefix,
        'data_bucket'  => $data_bucket,
      }
    ),
  } -> cron { 'every-minute-content-healthcheck':
    command     => "${base_dir}/aem-tools/content-healthcheck.py",
    user        => 'root',
    minute      => '*',
    environment => ["PATH=${env_path}", "https_proxy=\"${https_proxy}\""],
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
}

include publish_dispatcher
