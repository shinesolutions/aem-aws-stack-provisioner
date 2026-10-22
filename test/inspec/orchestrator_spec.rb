require_relative './spec_helper'

control 'aem-orchestrator' do
  describe group('aem-orchestrator') do
    it { should exist }
  end

  describe user('aem-orchestrator') do
    it { should exist }
    # its('group') { should eq 'orchestrator' }
  end

  describe service('aem-orchestrator') do
    it { should be_enabled }
    it { should be_running }
  end

  if os[:family].eql? 'amazon'
    describe command('/opt/puppetlabs/bin/puppet resource service aem-orchestrator ') do
      its(:stdout) { should match 'enable => \'true\'' }
    end
  end
end

control 'java' do
  describe command('java -version') do
    its('stdout') { should_not match(/openjdk/i) }
  end
end

control 'system-services' do
  describe_system_services(SYSTEM_SERVICES)
end
