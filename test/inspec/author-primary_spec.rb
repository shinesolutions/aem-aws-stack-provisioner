require_relative './spec_helper'

# inspec version 1.51.6. doesn't support Amazon Linux 2. It assumes it uses Upstart.
# inspec version is locked to 1.51.6 to use train version 0.32 because it doesn't have an aws-sdk dependency:
# https://github.com/inspec/inspec/blob/v1.51.6/inspec.gemspec#L29
# inspec supports amazon linux 2 from version v2.1.30 (2018-04-05)
# https://github.com/inspec/inspec/blob/master/CHANGELOG.md#v2130-2018-04-05
# remove this bespoke handling once upgraded.
if %w[amazon].include?(os[:name]) && !os[:release].start_with?('20\d\d')

  describe systemd_service('aem-author') do
    it { should be_enabled }
    it { should be_running }
  end

else

  describe service('aem-author') do
    it { should be_enabled }
    it { should be_running }
  end

end

describe port(4502) do
  it { should be_listening }
end

describe ssl(port: 4502) do
  it { should_not be_enabled }
end

describe port(5432) do
  it { should be_listening }
end

describe ssl(port: 5432) do
  it { should be_enabled }
end

describe command('java -version') do
  its('stdout') { should_not match /openjdk/i }
end
