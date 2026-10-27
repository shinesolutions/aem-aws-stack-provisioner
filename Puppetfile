forge 'https://forgeapi.puppetlabs.com'

# stdlib 9, concat 9 and archive 8 are the newest majors allowed by the collectd, logrotate, yum, java and apache bounds
mod 'puppetlabs/apache', '13.4.0'
mod 'puppet/archive', '8.1.0'
mod 'puppet-collectd', '16.0.0'
mod 'puppetlabs/concat', '9.1.0'
mod 'puppet-healthcheck', '2.1.0'
mod 'puppetlabs/java', '12.1.1'
# Required by puppet/systemd
mod 'puppetlabs/inifile', '6.5.0'
mod 'puppetlabs/java_ks', '6.1.0'
mod 'puppetlabs/selinux_core', '2.1.0'
mod 'puppet-logrotate', '9.0.0'
mod 'puppetlabs/stdlib', '9.7.0'
# Required by puppet-logrotate 9, which manages hourly rotation with systemd::unit_file.
# 9.4.0 is the latest version puppet-logrotate 9.0.0 allows (< 10.0.0), as in aem_curator's tests
mod 'puppet/systemd', '9.4.0'
mod 'puppet-yum', '8.3.0'
mod 'shinesolutions/aem_orchestrator', '3.1.0'
mod 'shinesolutions/aem_resources', '8.0.0'
# TODO: switch back to the Forge release 5.1.1 once it's published
mod 'shinesolutions/aem_curator',
  :git    => 'https://github.com/shinesolutions/puppet-aem-curator.git',
  :branch => 'feature/AOC-I22-accpetance-test'
mod 'shinesolutions/simianarmy', '1.1.4'
