require_relative './spec_helper'

init_conf

# TODO: re-enable tests when we have a better way to verify Chaos Monkey
# tomcat_srv_name = @hiera.lookup('chaos_monkey::tomcat_srv_name', nil, nil)
# tomcat_srv_name ||= 'tomcat'
#
# describe service(tomcat_srv_name) do
#   it { should be_enabled }
#   it { should be_running }
# end
