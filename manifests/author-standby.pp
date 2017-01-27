class author_standby (

) {

  class { 'aem_resources::author_set_as_standby':
    crx_quickstart_dir => '/opt/aem/author/crx-quickstart/',
    primary_host       => "${authorprimaryhost}",
  }

}

include author_standby
