require_relative './spec_helper'

describe group('aem-orchestrator') do
  it { should exist }
end

describe user('aem-orchestrator') do
  it { should exist }
  # its('group') { should eq 'orchestrator' }
end

if !os[:family].eql? 'amazon'
  describe service('aem-orchestrator') do
    # This check doesn't work on Amazon Linux because it doesn't check for
    # Upstart services.
    it { should be_enabled }
    it { should be_running }
  end
end

if os[:family].eql? 'amazon'
  describe command('/opt/puppetlabs/bin/puppet resource service aem-orchestrator ') do
    its(:stdout) { should match 'enable => \'true\'' }
  end
end

describe command('java -version') do
  its('stdout') { should_not match /openjdk/i }
end
