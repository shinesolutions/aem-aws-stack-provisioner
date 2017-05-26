File {
  backup => false,
}

class wait_until_ready (
) {

  aem_aem { 'Wait until login page is ready':
    ensure                     => login_page_is_ready,
    retries_max_tries          => 60,
    retries_base_sleep_seconds => 5,
    retries_max_sleep_seconds  => 5,
  } -> aem_aem { 'Wait until aem health check is ok':
    ensure                     => aem_health_check_is_ok,
    tags                       => 'deep',
    retries_max_tries          => 60,
    retries_base_sleep_seconds => 5,
    retries_max_sleep_seconds  => 5,
  }

}

include wait_until_ready
