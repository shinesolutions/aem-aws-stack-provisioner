File {
  backup => false,
}

class chaos_monkey (
  $component              = $::component,
  $stack_prefix           = $::stack_prefix,
  $orchestrator_asg       = $::orchestratorasg,
  $publish_asg            = $::publisherasg,
  $publish_dispatcher_asg = $::publisherdispatcherasg,
  $author_dispatcher_asg  = $::authordispatcherasg,
) {

  include simianarmy

  simianarmy::chaos_properties::asg { $::orchestratorasg:
    enabled                  => true,
    probability              => '1.0',
    max_terminations_per_day => '1.0',
  }
  # Chaos Monkey
  simianarmy::chaos_properties::asg { $facts['aws:autoscaling:groupname']:
    enabled                  => true,
    probability              => '1.0',
    max_terminations_per_day => '1.0',
  }
  # Publish
  simianarmy::chaos_properties::asg { $publish_asg:
    enabled                  => true,
    probability              => '1.0',
    max_terminations_per_day => '1.0',
  }
  # Publish-dispatcher
  simianarmy::chaos_properties::asg { $publish_dispatcher_asg:
    enabled                  => true,
    probability              => '1.0',
    max_terminations_per_day => '1.0',
  }
  # Author-Dispatcher
  simianarmy::chaos_properties::asg { $author_dispatcher_asg:
    enabled                  => true,
    probability              => '1.0',
    max_terminations_per_day => '1.0',
  }

  ##############################################################################
  # Update /etc/awslogs/awslogs.conf
  # to contain stack_prefix and component name
  ##############################################################################

  class { 'update_awslogs': }
}

class update_awslogs (
  $old_awslogs_content = file('/etc/awslogs/awslogs.conf'),
) {
  service { 'awslogs':
    ensure => 'running',
    enable => true
  }
  $mod_awslogs_content = regsubst($old_awslogs_content, '^log_group_name = ', "log_group_name = ${$stack_prefix}", 'G' )
  $new_awslogs_content = regsubst($mod_awslogs_content, '^log_stream_name = ', "log_stream_name = ${$component}/", 'G' )
  file { 'Update file /etc/awslogs/awslogs.conf':
    ensure  => file,
    content => $new_awslogs_content,
    path    => '/etc/awslogs/awslogs.conf',
    notify  => Service['awslogs'],
  }
}

include chaos_monkey
