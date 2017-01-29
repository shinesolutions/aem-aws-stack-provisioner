class publish (

) {

  service { 'aem-aem':
    ensure => 'running',
    enable => true,
  }

}

include publish
