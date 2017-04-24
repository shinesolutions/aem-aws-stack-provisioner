source ENV['GEM_SOURCE'] || "https://rubygems.org"

ENV['PUPPET_VERSION'].nil? ? puppetversion = '~> 4.0' : puppetversion = ENV['PUPPET_VERSION'].to_s
gem 'puppet', puppetversion, :require => false, :groups => [:test]
gem 'puppet-lint'
gem 'librarian-puppet'
