File {
  backup => false,
}

class author_standby (
  $base_dir,
  $aem_repo_devices,
  $author_primary_host = $::authorprimaryhost,
  $component           = $::component,
  $stack_prefix        = $::stack_prefix,
  $env_path            = $::cron_env_path,
  $https_proxy         = $::cron_https_proxy,
) {

  class { 'aem_curator::config_aem_tools':
  } -> class { 'aem_curator::config_aem_deployer':
  } -> class { 'aem_curator::config_author_standby':
    author_primary_host => $author_primary_host,
  } -> class { 'aem_curator::config_collectd':
  }

  ##############################################################################
  # Live snapshot backup
  ##############################################################################

  file { "${base_dir}/aem-tools/live-snapshot-backup.sh":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/live-snapshot-backup.sh.epp",
      {
        'base_dir'         => $base_dir,
        'aem_repo_devices' => $aem_repo_devices,
        'component'        => $component,
        'stack_prefix'     => $stack_prefix,
      }
    ),
  }

  if $enable_hourly_live_snapshot_cron {
    cron { 'hourly-live-snapshot-backup':
      command     => "${base_dir}/aem-tools/live-snapshot-backup.sh >>/var/log/live-snapshot-backup.log 2>&1",
      user        => 'root',
      hour        => '*',
      minute      => 0,
      environment => ["PATH=${env_path}", "https_proxy=\"${https_proxy}\""],
    }
  }

  ##############################################################################
  # Offline snapshot backup
  ##############################################################################

  file { "${base_dir}/aem-tools/offline-snapshot-backup.sh":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/offline-snapshot-backup.sh.epp",
      {
        'base_dir'         => $base_dir,
        'aem_repo_devices' => $aem_repo_devices,
        'component'        => $component,
        'stack_prefix'     => $stack_prefix,
      }
    ),
  }

  ##############################################################################
  # Collectd
  ##############################################################################

  class { 'aem_curator::config_collectd':
    proxy_protocol => $proxy_protocol,
    proxy_host     => $proxy_host,
    proxy_port     => $proxy_port,
  }

  file_line { 'seconds_since_last_success standby status':
    ensure => present,
    line   => "GenericJMX-${stack_prefix}-standby-status-delay-seconds_since_last_success",
    path   => '/opt/collectd-cloudwatch/src/cloudwatch/config/whitelist.conf',
  }

  collectd::plugin::genericjmx::connection { 'aem':
    host        => $::fqdn,
    service_url => "service:jmx:rmi:///jndi/rmi://localhost:${jmxremote_port}/jmxrmi",
    collect     => [ 'standby-status' ],
  }

  class { '::collectd':
    service_ensure => running,
    service_enable => true,
  }
}

include author_standby
