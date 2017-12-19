require './spec_helper'

init_conf

author_jvm_mem_options = @hiera.lookup('aem_curator::config_author_primary::jvm_mem_opts', nil, nil)
author_jvm_mem_options_string_length = author_jvm_mem_options.to_s.length

control 'Check author' do
  title 'Check AEM Author'
  desc 'Check if AEM Author is running and listening on configured ports and if it is running with configured memory'

  tag 'aem-authorh service'
  describe service('aem-author') do
    it { should be_enabled }
    it { should be_running }
  end

  tag 'port 4502'
  describe port(4502) do
    it { should be_listening }
  end

  tag 'port 5432'
  describe port(5432) do
    it { should be_listening }
  end

  if author_jvm_mem_options_string_length <= 2
   puts "JVM Memory value is standard. Check will be skipped."
  else
   tag 'aem-author memory'
   describe command('/bin/ps -U aem-author -o command') do
    its('stdout') {should match author_jvm_mem_options}
   end
  end
end
