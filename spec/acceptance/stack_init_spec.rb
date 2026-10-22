# frozen_string_literal: true

require 'spec_helper_acceptance'

# The steps of aem-aws-stack-builder's stack-init.sh that need neither AWS nor AEM, in its order: pre-common.pp,
# then for each component its manifest, action-scheduled-jobs.pp and its InSpec test.
#
# Each component manifest is compiled in full with the stack's hiera data, but only the resources of the classes
# below are applied (puppet apply --tags), as the others configure AEM or call AWS (S3, EC2, EBS).
# The InSpec tests run the controls that need neither (see test/inspec/spec_helper.rb).
# The components are provisioned one after the other on one host, as their non-AEM parts don't conflict.

LOGROTATE = %w[aem_curator::config_logrotate].freeze
# collectd and the scheduled offline compaction on the AEM instances
AEM = %w[aem_curator::config_collectd aem_curator::config_aem_scheduled_jobs].freeze
# The aem-tools dispatcher and deployer scripts and the dispatcher configuration
DISPATCHER_TOOLS = %w[aem_curator::config_aem_tools_dispatcher aem_curator::config_aem_deployer].freeze

# scheduled_jobs are the cron jobs action-scheduled-jobs.pp schedules for the component, from the jobs enabled in
# spec/fixtures/local.yaml, besides set-proxies, which every component has
COMPONENTS = {
  'author-primary' => {
    classes: LOGROTATE + AEM,
    controls: %w[system-services],
    scheduled_jobs: %w[export-backups live-snapshot-backup]
  },
  'author-standby' => {
    classes: LOGROTATE + %w[aem_curator::config_collectd],
    controls: %w[system-services],
    scheduled_jobs: %w[live-snapshot-backup]
  },
  'publish' => {
    classes: LOGROTATE + AEM,
    controls: %w[system-services],
    scheduled_jobs: %w[export-backups live-snapshot-backup]
  },
  'preview-publish' => {
    classes: LOGROTATE + AEM,
    controls: %w[system-services],
    scheduled_jobs: %w[live-snapshot-backup]
  },
  'author-dispatcher' => {
    classes: LOGROTATE + DISPATCHER_TOOLS + %w[aem_curator::config_author_dispatcher],
    controls: %w[dispatcher system-services],
    scheduled_jobs: []
  },
  'publish-dispatcher' => {
    classes: LOGROTATE + DISPATCHER_TOOLS + %w[aem_curator::config_publish_dispatcher],
    controls: %w[dispatcher system-services],
    scheduled_jobs: %w[content-health-check]
  },
  'preview-publish-dispatcher' => {
    classes: LOGROTATE + DISPATCHER_TOOLS + %w[aem_curator::config_publish_dispatcher],
    controls: %w[dispatcher system-services],
    scheduled_jobs: []
  },
  'author-publish-dispatcher' => {
    classes: LOGROTATE + AEM + DISPATCHER_TOOLS + %w[aem_curator::config_publish_dispatcher],
    controls: %w[dispatcher system-services],
    scheduled_jobs: %w[export-backups live-snapshot-backup stack-offline-compaction-snapshot stack-offline-snapshot]
  },
  'orchestrator' => {
    classes: LOGROTATE,
    controls: %w[system-services],
    scheduled_jobs: %w[stack-offline-compaction-snapshot stack-offline-snapshot]
  },
  'chaos-monkey' => {
    classes: LOGROTATE,
    controls: %w[system-services],
    scheduled_jobs: []
  }
}.freeze

describe 'stack-init.sh without AWS and AEM' do
  context 'with pre-common.pp' do
    # stack-init.sh applies it before set-facts.sh sets the component fact
    before(:all) { apply_provisioner_manifest('pre-common') }

    %w[set-component.sh set-facts.sh snapshot_backup.py snapshot_attach.py wait_for_ec2tags.py update_hiera.py
       update_snapshot_id_in_launch_template.py].each do |script|
      describe file("/opt/shinesolutions/aws-tools/#{script}") do
        it { is_expected.to be_file }
        it { is_expected.to be_mode 775 }
      end
    end

    describe file('/opt/shinesolutions/common-tools/run-adhoc-puppet.sh') do
      it { is_expected.to be_file }
    end

    describe file('/opt/shinesolutions/aem-tools/test-readiness.sh') do
      it { is_expected.to be_file }
    end

    # The InSpec AEM AWS profile the aem-tools scripts run
    describe file('/opt/shinesolutions/aem-tools/test/inspec/inspec-aem-aws/inspec.yml') do
      it { is_expected.to be_file }
    end

    %w[/root/.aws/config /home/ec2-user/.aws/config].each do |config|
      describe file(config) do
        its(:content) { is_expected.to match(/^region=ap-southeast-2$/) }
      end
    end

    describe file('/var/log/shinesolutions') do
      it { is_expected.to be_directory }
    end
  end

  COMPONENTS.each do |component, config|
    context "with the #{component} component" do
      before(:all) do
        apply_provisioner_manifest(component, component: component, tags: config[:classes])
        apply_provisioner_manifest('action-scheduled-jobs', component: component)
      end

      it 'schedules the jobs enabled in the stack configuration' do
        crontab = on(default, 'crontab -l -u root').stdout
        expect(crontab.scan(/^# Puppet Name: (.+)$/).flatten).to match_array(%w[set-proxies] + config[:scheduled_jobs])
      end

      # The rules come from the stack configuration, so this checks that they render to a valid configuration
      it 'has a logrotate configuration logrotate accepts' do
        expect(on(default, 'logrotate --debug /etc/logrotate.conf 2>&1').stdout).not_to match(/^error:/)
      end

      it 'passes the InSpec test controls that need neither AWS nor AEM' do
        run_component_inspec_test(component, controls: config[:controls])
      end
    end
  end
end
