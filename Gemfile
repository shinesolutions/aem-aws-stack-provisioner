source ENV['GEM_SOURCE'] || "https://rubygems.org"

ENV['PUPPET_VERSION'].nil? ? puppetversion = '~> 4.0' : puppetversion = ENV['PUPPET_VERSION'].to_s
gem 'puppet', puppetversion, :require => false, :groups => [:test]
gem 'puppet-lint'
gem 'librarian-puppet'

# The librarianp gem has a bug that's been fixed on GitHub but has not been
# released to RubyGems yet. We're pulling directly from GitHub to get the fix,
# but this should be removed once a release happens.
gem 'librarianp',
    git: 'https://github.com/voxpupuli/librarian.git',
    branch: 'librarianp'
