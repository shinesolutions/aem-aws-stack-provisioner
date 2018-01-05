File {
  backup => false,
}

class orchestrator (
  $base_dir,
  $offline_snapshot_hour = 1,
  $offline_snapshot_minute = 15,
  $enable_weekly_offline_compaction_snapshot = true,
) {

  Archive {
    checksum_verify => false,
  }

  include aem_orchestrator

  class { 'aem_curator::config_aem_tools':
  }

}

include orchestrator
