require_relative 'spec_helper'

describe service('aem-orchestrator') do
  it { should be_enabled }
  it { should be_running }
end
