File {
  backup => false,
}

class author_dispatcher (
  $base_dir,
  $tmp_dir,
  $dispatcher_conf_dir,
  $httpd_conf_dir,
  $docroot_dir,
  $ssl_cert,
  $author_port,
  $author_secure,
  $exec_path,
) {

  class { 'aem_resources::author_dispatcher_set_config':
    dispatcher_conf_dir => "${dispatcher_conf_dir}",
    httpd_conf_dir      => "${httpd_conf_dir}",
    docroot_dir         => "${docroot_dir}",
    ssl_cert            => $ssl_cert,
    author_host         => "${::authorhost}",
    author_port         => "${author_port}",
    author_secure       => "${author_secure}",
  } -> exec { 'httpd -k graceful':
    cwd  => "${tmp_dir}",
    path => $exec_path,
  } -> exec { 'deploy-artifacts.sh deploy-artifacts-descriptor.json':
    path        => $exec_path,
    environment => ["https_proxy=${::cron_https_proxy}"],
    cwd         => "${tmp_dir}",
    command     => "${base_dir}/aem-tools/deploy-artifacts.sh deploy-artifacts-descriptor.json >>/var/log/deploy-artifacts.log 2>&1",
    onlyif      => "test `aws s3 ls s3://${::data_bucket}/${::stackprefix}/deploy-artifacts-descriptor.json | wc -l` -eq 1",
    require     => [ File["${base_dir}/aem-tools/deploy-artifacts.sh"], File["${base_dir}/aem-tools/generate-artifacts-descriptor.py"] ],
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
  } -> file { "${base_dir}/aem-tools/generate-artifacts-descriptor.py":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/generate-artifacts-descriptor.py.epp", { 'tmp_dir' => "${tmp_dir}" }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/enter-standby.sh":
    ensure => present,
    source => "${base_dir}/aem-aws-stack-provisioner/files/aem-tools/enter-standby.sh",
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } -> file { "${base_dir}/aem-tools/exit-standby.sh":
    ensure => present,
    source => "${base_dir}/aem-aws-stack-provisioner/files/aem-tools/exit-standby.sh",
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  }


}

include author_dispatcher
