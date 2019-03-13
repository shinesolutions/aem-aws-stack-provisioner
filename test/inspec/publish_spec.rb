require_relative './spec_helper'

describe group('aem-publish') do
  it { should exist }
end

describe user('aem-publish') do
  it { should exist }
  its('group') { should eq 'aem-publish' }
end

# TODO: re-add this test after device name can be retrieved from a configuration
# describe etc_fstab.where { device_name == '/dev/xvdb' } do
#   its('mount_point') { should cmp '/mnt/ebs1' }
# end

describe file('/opt/aem/publish/crx-quickstart/repository') do
  its('type') { should eq :symlink }
  its('link_path') { should eq '/mnt/ebs1' }
  its('owner') { should eq 'aem-publish' }
  its('group') { should eq 'aem-publish' }
end

# inspec version 1.51.6. doesn't support Amazon Linux 2. It assumes it uses Upstart.
# inspec version is locked to 1.51.6 to use train version 0.32 because it doesn't have an aws-sdk dependency:
# https://github.com/inspec/inspec/blob/v1.51.6/inspec.gemspec#L29
# inspec supports amazon linux 2 from version v2.1.30 (2018-04-05)
# https://github.com/inspec/inspec/blob/master/CHANGELOG.md#v2130-2018-04-05
# remove this bespoke handling once upgraded.
if %w[amazon].include?(os[:name]) && !os[:release].start_with?('20\d\d')

  describe systemd_service('aem-publish') do
    it { should be_enabled }
    it { should be_running }
  end

else

  describe service('aem-publish') do
    it { should be_enabled }
    it { should be_running }
  end

end

describe port(4503) do
  it { should be_listening }
end

describe ssl(port: 4503) do
  it { should_not be_enabled }
end

describe port(5433) do
  it { should be_listening }
end

describe ssl(port: 5433) do
  it { should be_enabled }
end

describe command('java -version') do
  its('stdout') { should_not match(/openjdk/i) }
end
