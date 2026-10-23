source "https://rubygems.org"

# json 3 changed JSON.parse to keyword-only options, which breaks OpenVox 9's
# Puppet::Util::Json.load, and bundle install puts it in the agent's Ruby
gem 'json', '< 3', require: false
gem 'openvox', '9.0.0', require: false
gem 'puppet-lint', '5.1.1', require: false
gem 'r10k', '5.0.3', require: false
gem 'rubocop', '1.90.0', require: false
gem 'yaml-lint', '0.1.2', require: false
