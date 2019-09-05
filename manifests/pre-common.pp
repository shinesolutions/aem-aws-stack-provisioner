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
  $aem_tools_env_path  = '$PATH:/opt/puppetlabs/puppet/bin',
  $extra_packages      = [],
  $enable_chaos_monkey = true,
  $template_dir        = undef,
  $file_dir            = undef,
  $stack_prefix        = $::stack_prefix,
  $data_bucket_name    = $::data_bucket_name,
  $log_dir             = '/var/log/shinesolutions',
) {

  firewall { '101 accept all to lo interface':
    proto     => 'all',
    chain     => 'INPUT',
    iniface   => 'lo',
    action    => 'accept',
  }
  firewall {'102 reject local traffic not on loopback interface':
    iniface     => '! lo',
    chain       => 'INPUT',
    proto       => 'all',
    destination => '127.0.0.1/8',
    action      => 'reject',
  }
  firewall { '103 accept related established rules':
    proto  => 'all',
    chain  => 'INPUT',
    state  => ['RELATED', 'ESTABLISHED'],
    action => 'accept',
  }
  firewall { '104 allow ssh port 22 access':
    port    => '22',
    proto   => tcp,
    action  => accept,
    chain   => 'INPUT',
  }
  firewall { '105 allow NTP IN':
    chain => 'INPUT',
    port => '123',
    proto => udp,
    action => accept,
  }
  firewall { '106 allow NTP OUT':
    chain => 'OUTPUT',
    port => '123',
    proto => udp,
    action => accept,
  }
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

  ##############################################################################
  # AEM Readiness test
  ##############################################################################

  file { "${base_dir}/aem-tools/test-readiness.sh":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/test-readiness.sh.epp",
      {
        'aem_tools_env_path'  => $aem_tools_env_path,
        'base_dir'            => $base_dir,
        'enable_chaos_monkey' => $enable_chaos_monkey,
      }
    ),
  }
}

include pre_common
