require_relative 'spec_helper'

# Service will be renamed to 'aem' on next puppet-aem release.
# https://github.com/bstopp/puppet-aem/commit/a28d87fbf6bafc81ff00dec1759d8848708f32af
describe service('aem-aem') do
  it { should be_enabled }
  it { should be_running }
end

describe port(4503) do
  it { should be_listening }
end

describe port(5433) do
  it { should be_listening }
end
