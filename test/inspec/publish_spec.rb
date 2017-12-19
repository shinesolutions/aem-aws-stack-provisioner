require './spec_helper'

init_conf

publish_jvm_mem_options = @hiera.lookup('aem_curator::config_publish::jvm_mem_opts', nil, nil)
publish_jvm_mem_options_string_length = publish_jvm_mem_options.to_s.length

control 'Check Publisher' do
  title 'Check AEM Publisher'
  desc 'Check if AEM Publisher is running and listening on configured ports and if it is running with configured memory'

  tag 'aem-publish service'
  describe service('aem-publish') do
    it { should be_enabled }
    it { should be_running }
  end

  tag 'port 4503'
  describe port(4503) do
    it { should be_listening }
  end

  tag 'port 5433'
  describe port(5433) do
    it { should be_listening }
  end

  if publish_jvm_mem_options_string_length <= 2
   puts "JVM Memory value is standard. Check will be skipped."
  else 
   tag 'aem-publish memory'
   describe command('/bin/ps -U aem-publish -o command') do
    its('stdout') {should match publish_jvm_mem_options}
   end
  end
end
