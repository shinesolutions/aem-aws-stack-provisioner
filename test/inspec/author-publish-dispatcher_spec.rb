require_relative './spec_helper'

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

describe service('httpd') do
  it { should be_enabled }
  it { should be_running }
end

describe port(80) do
  it { should be_listening }
end

describe ssl(port: 80) do
  it { should_not be_enabled }
end

describe port(443) do
  it { should be_listening }
end

describe ssl(port: 443) do
  it { should be_enabled }
end

describe command('java -version') do
  its('stdout') { should_not match /openjdk/i }
end
