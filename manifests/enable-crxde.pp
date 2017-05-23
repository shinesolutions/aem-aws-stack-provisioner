class enable_crxde() {
  class { 'aem_resources::enable_crxde':
    run_mode => 'author',
  }
}

include enable_crxde
