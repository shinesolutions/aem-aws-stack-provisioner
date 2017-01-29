class author_primary (

) {

  service { 'aem-aem':
    ensure => 'running',
    enable => true,
  }

}

include author_primary
