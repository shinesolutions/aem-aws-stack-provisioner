class common (
  $base_dir,
  $tmp_dir,
  $aws_region,
  $user,
  $group,
){

  file { "${tmp_dir}":
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  }

  # Set up AWS region for root user
  file { '/root/.aws/':
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } ->
  file { '/root/.aws/credentials':
    ensure  => file,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aws/credentials.epp", { 'region' => "${aws_region}" }),
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
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aws/credentials.epp", { 'region' => "${aws_region}" }),
    mode    => '0664',
    owner   => "${user}",
    group   => "${group}",
  }

  # Set up AWS tools
  file { "${base_dir}/aws-tools/":
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  }
  file { "${base_dir}/aws-tools/set-component.sh":
    ensure  => file,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aws/set-component.sh.epp", { 'base_dir' => "${base_dir}" }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    require => File["${base_dir}/aws-tools/"],
  }
  file { "${base_dir}/aws-tools/set-facts.sh":
    ensure  => present,
    source  => "${base_dir}/aem-aws-stack-provisioner/files/aws/set-facts.sh",
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    require => File["${base_dir}/aws-tools/"],
  }
  file { "${base_dir}/aws-tools/wait_for_ec2tag.py":
    ensure  => present,
    source  => "${base_dir}/aem-aws-stack-provisioner/files/aws/wait_for_ec2tag.py",
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    require => File["${base_dir}/aws-tools/"],
  }

}

include common
