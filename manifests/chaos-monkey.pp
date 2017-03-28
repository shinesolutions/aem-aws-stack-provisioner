class chaos_monkey (

) {

  include simianarmy

  simianarmy::chaos_properties::asg { $::OrchestratorASG:
    enabled                  => true,
    probability              => 0.5,
    max_terminations_per_day => 1.0,
    owner_email              => 'owner@domain.com',
  }
  # Chaos Monkey
  simianarmy::chaos_properties::asg { $::aws_autoscaling_groupName:
    enabled                  => true,
    probability              => 0.5,
    max_terminations_per_day => 1.0,
    owner_email              => 'owner@domain.com',
  }
  # Publish
  simianarmy::chaos_properties::asg { $::PublisherASG:
    enabled                  => true,
    probability              => 0.5,
    max_terminations_per_day => 1.0,
    owner_email              => 'owner@domain.com',
  }
  # Publish-dispatcher
  simianarmy::chaos_properties::asg { $::PublisherDispatcherASG:
    enabled                  => true,
    probability              => 0.5,
    max_terminations_per_day => 1.0,
    owner_email              => 'owner@domain.com',
  }
  # Author-Dispatcher
  simianarmy::chaos_properties::asg { $::AuthorDispatcherASG:
    enabled                  => true,
    probability              => 0.5,
    max_terminations_per_day => 1.0,
    owner_email              => 'owner@domain.com',
  }

}

include chaos_monkey
