require 'spec_helper'

aem_port = @hiera.lookup('author_primary::aem_port', nil, @scope)
aem_port ||= '4502'

# Service will be renamed to 'aem' on next puppet-aem release.
# https://github.com/bstopp/puppet-aem/commit/a28d87fbf6bafc81ff00dec1759d8848708f32af
describe service('aem-aem') do
  it { should be_enabled }
  it { should be_running }
end

describe port(aem_port) do
  it { should be_listening }
end
