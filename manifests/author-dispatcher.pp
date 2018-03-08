File {
  backup => false,
}

class author_dispatcher (
  $base_dir,
  $author_host = $::authorhost,
  $docroot_dir = lookup('common::docroot_dir'),
) {

  class { 'aem_curator::config_aem_tools_dispatcher':
    docroot_dir => $docroot_dir,
  } -> class { 'aem_curator::config_aem_deployer':
  } -> class { 'aem_curator::config_author_dispatcher':
    author_host => $author_host,
    docroot_dir => $docroot_dir,
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
