require_relative './spec_helper'

describe service('aem-publish') do
  it { should be_enabled }
  it { should be_running }
end

describe port(4503) do
  it { should be_listening }
end

describe port(5433) do
  it { should be_listening }
end
