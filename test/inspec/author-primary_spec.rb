require_relative './spec_helper'

describe group('aem-author') do
  it { should exist }
end

describe user('aem-author') do
  it { should exist }
  its('group') { should eq 'aem-author' }
end

describe etc_fstab.where { device_name == '/dev/xvdb' } do
  its('mount_point') { should cmp '/mnt/ebs1' }
end

describe file('/opt/aem/author/crx-quickstart/repository') do
  its('type') { should eq :symlink }
  its('link_path') { should eq '/mnt/ebs1' }
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

describe port(5432) do
  it { should be_listening }
end

describe ssl(port: 5432) do
  it { should be_enabled }
end

describe command('java -version') do
  its('stdout') { should_not match /openjdk/i }
end
