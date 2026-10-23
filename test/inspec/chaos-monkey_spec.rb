require_relative './spec_helper'

# init_conf

# TODO: re-enable hiera lookup when we have a better way to lookup the hiera params
# tomcat_srv_name = @hiera.lookup('chaos_monkey::tomcat_srv_name', nil, nil)
tomcat_srv_name ||= 'tomcat'

control 'simian-army' do
  describe service(tomcat_srv_name) do
    it { should be_enabled }
    it { should be_running }
  end

  # Only checked on other OSes than Amazon Linux before, by the Amazon Linux 2 workaround for InSpec 1.51.6
  describe file('/var/log/tomcat/simianarmy.log') do
    it { should exist }
  end
end

control 'java' do
  describe command('java -version') do
    its('stdout') { should_not match(/openjdk/i) }
  end
end

control 'system-services' do
  describe_system_services(SYSTEM_SERVICES)
end
