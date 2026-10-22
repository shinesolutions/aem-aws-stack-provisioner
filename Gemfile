source ENV['GEM_SOURCE'] || 'https://rubygems.org'

group :development, :test do
  # OpenVox 9 calls JSON.parse(string, options), which json 3 no longer accepts
  gem 'json',                '~> 2.21'
  # Installs the Puppetfile modules
  gem 'r10k',                '~> 5.0', require: false
  # Provides OpenVox, puppet-lint (with the Vox Pupuli plugins) and rubocop
  gem 'voxpupuli-test',      '~> 15.0', require: false
  # Runs the acceptance tests in spec/acceptance with Beaker on Docker
  gem 'voxpupuli-acceptance', '~> 4.4', require: false
  # Test-only: installed on the acceptance test hosts at this version, as the AMIs provide it for the
  # shinesolutions/aem_resources providers, which `require 'ruby_aem'` when a manifest is applied
  gem 'ruby_aem',            '~> 4.1.0', require: false
  # Loaded as a plugin in .rubocop.yml, not a dependency of voxpupuli-test
  gem 'rubocop-performance', '~> 1.27', require: false
end
