# facter and hiera aren't required at the top any more: facter 4 needs thor < 1.3 but Cinc InSpec 7 ships thor 1.4,
# so `require 'facter'` failed every spec before it ran (and nothing used it), and hiera isn't part of Cinc InSpec.
# hiera is only required by init_conf, whose use is disabled (see chaos-monkey_spec.rb)

# The system services that every component's provisioning relies on, checked by each component spec:
# - crond runs the crontab entries of manifests/action-scheduled-jobs.pp (which stack-init.sh applies to every
#   component) and puppet-logrotate's /etc/cron.daily and /etc/cron.hourly scripts. Amazon Linux 2023 doesn't
#   install cronie by default, so the AMI has to provide it
# - awslogs ships the logs to CloudWatch. It's optional: the component manifests only start it (update_awslogs)
#   when its configuration (common::awslogs_config_path) exists, i.e. the AMI was baked with it, so it's only
#   checked then. Amazon Linux 2023 has no awslogs, see the amazon-cloudwatch-agent TODO in data/common.yaml
SYSTEM_SERVICES = %w[crond].freeze
AWSLOGS_SERVICE = 'awslogs'.freeze
AWSLOGS_CONFIG_PATH = '/etc/awslogs/awslogs.conf'.freeze

# collectd collects the AEM JMX metrics, set up by aem_curator::config_collectd on the AEM components
AEM_SYSTEM_SERVICES = (SYSTEM_SERVICES + %w[collectd]).freeze

def init_conf
  require 'hiera'
  hiera_conf = File.expand_path(File.join(__FILE__, '../../../../conf/hiera.yaml'))
  @hiera = Hiera.new(config: hiera_conf)
end

# Each service must be enabled, so it starts again after a reboot, and running
def describe_system_services(services)
  services += [AWSLOGS_SERVICE] if file(AWSLOGS_CONFIG_PATH).exist?
  services.each do |name|
    describe service(name) do
      it { should be_enabled }
      it { should be_running }
    end
  end
end
