require_relative './spec_helper'

describe service('aem-author') do
  it { should be_enabled }
  it { should be_running }
end

describe port(4502) do
  it { should be_listening }
end

describe port(5432) do
  it { should be_listening }
end

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

describe service('httpd') do
  it { should be_enabled }
  it { should be_running }
end

describe port(80) do
  it { should be_listening }
end

describe port(443) do
  it { should be_listening }
end
