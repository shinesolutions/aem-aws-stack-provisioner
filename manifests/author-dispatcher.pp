File {
  backup => false,
}

class author_dispatcher (
  $base_dir,
  $docroot_dir,
  $author_host        = $::authorhost,
  $stack_prefix       = $::stack_prefix,
  $data_bucket_name   = $::data_bucket_name,
  $exec_path          = ['/bin', '/usr/local/bin', '/usr/bin'],
  $aem_tools_env_path = '$PATH:/opt/puppetlabs/puppet/bin',
  $https_proxy        = $::cron_https_proxy,
) {

  class { 'aem_curator::config_aem_tools_dispatcher':
    aem_tools_env_path => $aem_tools_env_path
  } -> class { 'aem_curator::config_aem_deployer':
    aem_tools_env_path => $aem_tools_env_path
  } -> class { 'aem_curator::config_author_dispatcher':
    author_host => $author_host,
    docroot_dir => $docroot_dir,
  } -> exec { 'Deploy Author-Dispatcher artifacts':
    path        => $exec_path,
    environment => ["https_proxy=${https_proxy}"],
    cwd         => $tmp_dir,
    command     => "${base_dir}/aem-tools/deploy-artifacts.sh deploy-artifacts-descriptor.json >>/var/log/puppet-deploy-artifacts.log 2>&1",
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
}

include author_dispatcher
