require_relative './spec_helper'

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
