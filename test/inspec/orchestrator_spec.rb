require_relative './spec_helper'

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
