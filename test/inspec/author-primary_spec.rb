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

describe command('java -version') do
  its('stdout') { should_not match /openjdk/i }
end
