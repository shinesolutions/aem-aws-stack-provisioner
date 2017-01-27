class author_standby (

) {

  class { 'aem_resources::author_standby_set_config':
    install_dir  => '/opt/aem/author/crx-quickstart/install',
    primary_host => "${authorprimaryhost}",
  }

}

include author_standby
