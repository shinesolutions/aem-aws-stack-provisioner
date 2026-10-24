require_relative './spec_helper'

control 'aem-author' do
  describe group('aem-author') do
    it { should exist }
  end

  describe user('aem-author') do
    it { should exist }
    its('group') { should eq 'aem-author' }
  end

  # TODO: re-add this test after device name can be retrieved from a configuration
  # describe etc_fstab.where { device_name == '/dev/xvdb' } do
  #   its('mount_point') { should cmp '/mnt/ebs1' }
  # end

  describe file('/opt/aem/author') do
    its('type') { should eq :symlink }
    its('link_path') { should eq '/mnt/ebs1/author' }
    its('owner') { should eq 'aem-author' }
    its('group') { should eq 'aem-author' }
  end

  describe service('aem-author') do
    it { should be_enabled }
    it { should be_running }
  end

  describe port(4502) do
    it { should be_listening }
  end

  describe ssl(port: 4502) do
    it { should_not be_enabled }
  end
end

control 'system-services' do
  describe_system_services(AEM_SYSTEM_SERVICES)
end
