File {
  backup => false,
}

class chaos_monkey (
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

}

include chaos_monkey
