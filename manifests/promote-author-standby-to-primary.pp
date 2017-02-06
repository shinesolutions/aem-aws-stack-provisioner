class promote_author_standby_to_primary (

) {

  exec { 'service aem-aem stop':
    cwd  => '/tmp',
    path => ['/usr/bin', '/usr/sbin'],
  } ->
  exec { 'set-component.sh author-primary':
    cwd  => '/tmp',
    path => ['/opt/shinesolutions/aws-tools'],
  } ->
  class { 'aem_resources::author_primary_set_config':
    crx_quickstart_dir => '/opt/aem/author/crx-quickstart',
  } ->
  service { 'aem-aem':
    ensure => 'running',
    enable => true,
  } ->
  aem_aem { 'Wait until login page is ready':
    ensure => login_page_is_ready,
  }

}

include promote_author_standby_to_primary
