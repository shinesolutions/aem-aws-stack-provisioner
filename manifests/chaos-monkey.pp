class chaos_monkey (

) {

  include simianarmy

  simianarmy::chaos_properties::asg { $::orchestratorasg:
    enabled                  => true,
    probability              => 0.5,
    max_terminations_per_day => 1.0,
  }
  # Chaos Monkey
  simianarmy::chaos_properties::asg { $facts['aws:autoscaling:groupname']:
    enabled                  => true,
    probability              => 0.5,
    max_terminations_per_day => 1.0,
  }
  # Publish
  simianarmy::chaos_properties::asg { $::publisherasg:
    enabled                  => true,
    probability              => 0.5,
    max_terminations_per_day => 1.0,
  }
  # Publish-dispatcher
  simianarmy::chaos_properties::asg { $::publisherdispatcherasg:
    enabled                  => true,
    probability              => 0.5,
    max_terminations_per_day => 1.0,
  }
  # Author-Dispatcher
  simianarmy::chaos_properties::asg { $::authordispatcherasg:
    enabled                  => true,
    probability              => 0.5,
    max_terminations_per_day => 1.0,
  }

}

include chaos_monkey
