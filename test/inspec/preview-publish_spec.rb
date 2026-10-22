require_relative './spec_helper'

control 'aem-publish' do
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

  describe file('/opt/aem/publish') do
    its('type') { should eq :symlink }
    its('link_path') { should eq '/mnt/ebs1/publish' }
    its('owner') { should eq 'aem-publish' }
    its('group') { should eq 'aem-publish' }
  end

  describe service('aem-publish') do
    it { should be_enabled }
    it { should be_running }
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
end

control 'java' do
  describe command('java -version') do
    its('stdout') { should_not match(/openjdk/i) }
  end
end

control 'system-services' do
  describe_system_services(AEM_SYSTEM_SERVICES)
end
