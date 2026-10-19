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
# Required by puppet-logrotate 9, which manages hourly rotation with systemd::unit_file
mod 'puppet/systemd', '10.3.0'
mod 'puppet-yum', '8.3.0'
# Needed by aem_curator 4.1.9; remove when aem_curator/aem_resources are bumped, as it moves into them
mod 'bstopp/aem', '3.0.0'
mod 'shinesolutions/aem_orchestrator', '3.0.2'
# aem_resources stays on 7.10.2 (not 7.11.0) as aem_curator 4.1.9 pins it
mod 'shinesolutions/aem_resources', '7.10.2'
mod 'shinesolutions/aem_curator', '4.1.9'
mod 'shinesolutions/simianarmy', '1.1.4'
