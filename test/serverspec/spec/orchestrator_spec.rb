require_relative 'spec_helper'

describe service('aem-orchestrator') do
  if os[:family] != 'amazon'
    # This check doesn't work on Amazon Linux because it doesn't check for
    # Upstart services.
    it { should be_enabled }
  end
  it { should be_running }
end

if os[:family] == 'amazon'
  describe command('/opt/puppetlabs/bin/puppet resource service aem-orchestrator ') do
    its(:stdout) { should match 'enable => \'true\'' }
  end
end
