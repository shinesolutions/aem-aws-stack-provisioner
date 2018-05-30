File {
  backup => false,
}

class pre_common (
  $base_dir,
  $tmp_base_dir,
  $tmp_dir,
  $aws_region,
  $user,
  $group,
  $credentials_file,
  $extra_packages    = [],
  $template_dir      = undef,
  $file_dir          = undef,
  $stack_prefix      = $::stack_prefix,
  $data_bucket_name  = $::data_bucket_name,
  $log_dir           = '/var/log/shinesolutions',
) {
  $template_dir_final = pick(
    $template_dir,
    "${base_dir}/aem-aws-stack-provisioner/templates"
  )

  $file_dir_final = pick(
    $file_dir,
    "${base_dir}/aem-aws-stack-provisioner/files"
  )

  # Ensure we have a working FQDN <=> IP mapping.
  host { $facts['fqdn']:
    ensure       => present,
    ip           => $facts['ipaddress'],
    host_aliases => $facts['hostname'],
  }

  package { $extra_packages:
    ensure => present,
  }

  file { "${tmp_base_dir}":
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } -> file { "${tmp_dir}":
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  }

  # Create log directory
  file { "${log_dir}":
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
  } -> file { '/root/.aws/credentials':
    ensure  => file,
    content => epp("${template_dir_final}/aws/credentials.epp", { 'region' => "${aws_region}" }),
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
  } -> file { "/home/${user}/.aws/credentials":
    ensure  => file,
    content => epp("${template_dir_final}/aws/credentials.epp", { 'region' => "${aws_region}" }),
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
    content => epp("${template_dir_final}/aws-tools/set-component.sh.epp", {'base_dir' => "${base_dir}",}),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    require => File["${base_dir}/aws-tools/"],
  }

  file { "${base_dir}/aws-tools/set-facts.sh":
    ensure  => present,
    source  => "${file_dir_final}/aws-tools/set-facts.sh",
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    require => File["${base_dir}/aws-tools/"],
  }

  file { "${base_dir}/aws-tools/snapshot_backup.py":
    ensure  => present,
    source  => "${file_dir_final}/aws-tools/snapshot_backup.py",
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    require => File["${base_dir}/aws-tools/"],
  }

  file { "${base_dir}/aws-tools/snapshot_attach.py":
    ensure  => present,
    source  => "${file_dir_final}/aws-tools/snapshot_attach.py",
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    require => File["${base_dir}/aws-tools/"],
  }

  file { "${base_dir}/aws-tools/wait_for_ec2tags.py":
    ensure  => present,
    source  => "${file_dir_final}/aws-tools/wait_for_ec2tags.py",
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    require => File["${base_dir}/aws-tools/"],
  }

  file { "${base_dir}/aws-tools/update_hiera.py":
    ensure  => present,
    source  => "${file_dir_final}/aws-tools/update_hiera.py",
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    require => File["${base_dir}/aws-tools/"],
  }

  file { "${base_dir}/aws-tools/update_snapshot_id_in_launch_conf.py":
    ensure  => present,
    source  => "${file_dir_final}/aws-tools/update_snapshot_id_in_launch_conf.py",
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    require => File["${base_dir}/aws-tools/"],
  }

  file { "${base_dir}/aem-tools/":
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } -> file {"${base_dir}/aem-tools/test":
    ensure  => directory,
    source  => "${file_dir_final}/test",
    recurse => true,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

  # set up common tools
  file {"${base_dir}/common-tools":
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  }
  -> file {"${base_dir}/common-tools/run-adhoc-puppet.sh":
    ensure => present,
    source => "file://${base_dir}/aem-aws-stack-provisioner/files/common-tools/run-adhoc-puppet.sh",
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  }

  # Download credentials file from S3 to temp directory, these credentials will
  # used for component provisioning and will be cleaned up at the end of stack
  # initialisation.
  archive { "${tmp_dir}/${credentials_file}":
    ensure => present,
    source => "s3://${data_bucket_name}/${stack_prefix}/${credentials_file}"
  }
}

include pre_common
