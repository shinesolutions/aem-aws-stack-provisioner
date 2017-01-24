class common (
  $base_dir,
  $aws_region,
  $user,
  $group,
){

  # Set up AWS region for root user
  file { '/root/.aws/':
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } ->
  file { '/root/.aws/credentials':
    ensure  => file,
    content => epp("${base_dir}/templates/aws/credentials.epp", { 'region' => "${aws_region}" }),
    mode    => '0664',
    owner   => 'root',
    group   => 'root',
  }

  # Set up AWS region for non-root user
  file { "/home/${user}/.aws/":
    ensure => directory,
    mode   => '0775',
    owner  => "${user}",
    group  => "${group}",
  } ->
  file { "/home/${user}/.aws/credentials":
    ensure  => file,
    content => epp("${base_dir}/templates/aws/credentials.epp", { 'region' => "${aws_region}" }),
    mode    => '0664',
    owner   => "${user}",
    group   => "${group}",
  }

  # Set up AWS tools
  file { '/opt/aws-tools/':
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } ->
  file { '/opt/aws-tools/ec2tags-facts.sh':
    ensure => present,
    source => "${base_dir}/files/facter/ec2tags-facts.sh",
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  }

}

include common
