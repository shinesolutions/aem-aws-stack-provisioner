File {
  backup => false,
}

class chaos_monkey (
  $awslogs_config_path,
  $orchestrator_enable_random_termination       = true,
  $chaos_monkey_enable_random_termination       = true,
  $publish_enable_random_termination            = true,
  $publish_dispatcher_enable_random_termination = true,
  $author_dispatcher_enable_random_termination  = true,
  $component                                    = $::component,
  $stack_prefix                                 = $::stack_prefix,
  $orchestrator_asg                             = $::orchestratorasg,
  $publish_asg                                  = $::publisherasg,
  $publish_dispatcher_asg                       = $::publisherdispatcherasg,
  $author_dispatcher_asg                        = $::authordispatcherasg,
  $asg_probability                              = $::asg_probability,
  $asg_max_terminations_per_day                 = $::asg_max_terminations_per_day,
  $ssh_public_keys,
  $aws_user = 'ec2-user',
) {

  $ssh_public_keys.each | String $name, Hash $ssh_details| {
    $ssh_public_key      = $ssh_details['public_key']
    $ssh_public_key_type = $ssh_details['public_key_type']

      notify{"ssh details: ${ssh_public_key}":}

    ssh_authorized_key { "Adding public key for user ${name} to authorized_keys":
      ensure   => present,
      user     => $aws_user,
      provider => 'parsed',
      name     => $name,
      key      => $ssh_public_key,
      type     => $ssh_public_key_type,
    }
  }
  class { 'simianarmy':
  } -> simianarmy::chaos_properties::asg { $::orchestratorasg:
    enabled                  => $orchestrator_enable_random_termination,
    probability              => $asg_probability,
    max_terminations_per_day => $asg_max_terminations_per_day,
  } -> simianarmy::chaos_properties::asg { $facts['aws:autoscaling:groupname']:
    enabled                  => $chaos_monkey_enable_random_termination,
    probability              => $asg_probability,
    max_terminations_per_day => $asg_max_terminations_per_day,
  } -> simianarmy::chaos_properties::asg { $publish_asg:
    enabled                  => $publish_enable_random_termination,
    probability              => $asg_probability,
    max_terminations_per_day => $asg_max_terminations_per_day,
  } -> simianarmy::chaos_properties::asg { $publish_dispatcher_asg:
    enabled                  => $publish_dispatcher_enable_random_termination,
    probability              => $asg_probability,
    max_terminations_per_day => $asg_max_terminations_per_day,
  } -> simianarmy::chaos_properties::asg { $author_dispatcher_asg:
    enabled                  => $author_dispatcher_enable_random_termination,
    probability              => $asg_probability,
    max_terminations_per_day => $asg_max_terminations_per_day,
  }

  ##############################################################################
  # Update AWS Logs proxy settings file
  # to contain stack_prefix and component name
  ##############################################################################

  class { 'update_awslogs':
    config_file_path => $awslogs_config_path
  }

  ##############################################################################
  # Configure logrotation
  ##############################################################################

  class { 'aem_curator::config_logrotate': }
}

class update_awslogs (
  $config_file_path,
  $awslogs_service_name = lookup('common::awslogs_service_name')
) {
  service { $awslogs_service_name:
    ensure => 'running',
    enable => true
  }
  $old_awslogs_content = file($config_file_path)
  $mod_awslogs_content = regsubst($old_awslogs_content, '^log_group_name = ', "log_group_name = ${$stack_prefix}", 'G' )
  $new_awslogs_content = regsubst($mod_awslogs_content, '^log_stream_name = ', "log_stream_name = ${$component}/", 'G' )
  file { 'Update AWS Logs proxy settings file':
    ensure  => file,
    content => $new_awslogs_content,
    path    => $config_file_path,
    notify  => Service[$awslogs_service_name],
  }
}

include chaos_monkey
