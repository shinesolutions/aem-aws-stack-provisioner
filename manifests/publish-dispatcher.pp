class publish_dispatcher (
  $base_dir,
  $tmp_dir,
  $dispatcher_conf_dir,
  $httpd_conf_dir,
  $docroot_dir,
  $publish_port,
  $publish_secure,
) {

  # Prepare AEM unified dispatcher certificate
  archive { "${tmp_dir}/aem.cert":
    ensure => present,
    source => "s3://${::data_bucket}/${::stackprefix}/aem.cert",
  }

  archive { "${tmp_dir}/aem.key":
    ensure => present,
    source => "s3://${::data_bucket}/${::stackprefix}/aem.key",
  }

  file { '/etc/httpd/aem.disp-cert':
    ensure => absent,
  }

  exec { "cat ${tmp_dir}/aem.key >> /etc/httpd/aem.disp-cert":
    cwd  => "${tmp_dir}",
    path => ['/usr/bin'],
  }

  exec { "cat ${tmp_dir}/aem.cert >> /etc/httpd/aem.disp-cert":
    cwd  => "${tmp_dir}",
    path => ['/usr/bin'],
  }

  file { "${tmp_dir}/aem.cert":
    ensure => absent,
  }

  file { "${tmp_dir}/aem.key":
    ensure => absent,
  }

  class { 'aem_resources::publish_dispatcher_set_config':
    dispatcher_conf_dir => "${dispatcher_conf_dir}",
    httpd_conf_dir      => "${httpd_conf_dir}",
    docroot_dir         => "${docroot_dir}",
    allowed_client      => "${::publish_dispatcher_allowed_client}",
    publish_host        => "${::publishhost}",
    publish_port        => "${publish_port}",
  } -> exec { 'httpd -k graceful':
    cwd  => "${tmp_dir}",
    path => ['/sbin'],
  } -> exec { 'deploy-artifacts.sh deploy-artifacts-descriptor.json':
    path        => ["${base_dir}/aem-tools", '/usr/bin', '/opt/puppetlabs/bin'],
    environment => ["https_proxy=\"${::cron_https_proxy}\""],
    cwd         => "${tmp_dir}",
    command     => "${base_dir}/aem-tools/deploy-artifacts.sh deploy-artifacts-descriptor.json >>/var/log/deploy-artifacts.log 2>&1",
    onlyif      => "test `aws s3 ls s3://${::data_bucket}/${::stackprefix}/deploy-artifacts-descriptor.json | wc -l` -eq 1",
    require     => [ File["${base_dir}/aem-tools/deploy-artifacts.sh"], File["${base_dir}/aem-tools/generate-artifacts-json.py"] ],
  }

  # Set up AEM tools
  file { "${base_dir}/aem-tools/":
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } -> file { "${base_dir}/aem-tools/deploy-artifacts.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/deploy-artifacts.sh.epp", { 'base_dir' => "${base_dir}" }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/generate-artifacts-json.py":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/generate-artifacts-json.py.epp", { 'tmp_dir' => "${tmp_dir}" }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

  file { "${base_dir}/aem-tools/content-healthcheck.py":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/content-healthcheck.py.epp", {
      'tmp_dir'      => "${tmp_dir}",
      'stack_prefix' => "${::stackprefix}",
      'data_bucket'  => "${::data_bucket}",
    }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> cron { 'every-minute-content-healthcheck':
    command     => "${base_dir}/aem-tools/content-healthcheck.py",
    user        => 'root',
    minute      => '*',
    environment => ["PATH=${::cron_env_path}", "https_proxy=\"${::cron_https_proxy}\""],
  }

}

include publish_dispatcher
