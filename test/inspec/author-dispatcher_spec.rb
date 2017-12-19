require './spec_helper'

init_conf

control 'Check HTTPD Process' do
  title 'Check HTTPD Process'
  desc 'Check if httpd process is running and listeninglon configured ports'

  tag 'Check_httpd_process'
  describe service('httpd') do
    it { should be_enabled }
    it { should be_running }
  end

  tag 'Check_http_port'
  describe port(80) do
    it { should be_listening }
  end

  tag 'Check_https_port'
  describe port(443) do
    it { should be_listening }
  end
end

