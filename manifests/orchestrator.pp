class orchestrator (
) {
  Archive {
    checksum_verify => false,
  }
  include aem_orchestrator
}

include orchestrator
