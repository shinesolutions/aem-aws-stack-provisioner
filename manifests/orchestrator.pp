class orchestrator (

) {

  class { 'aem_orchestrator':
    jarfile_source => 'https://s3-ap-southeast-2.amazonaws.com/aem-stack-builder/aem-orchestrator-0.9.0.jar',
  }

}

include orchestrator
