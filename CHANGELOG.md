# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Add new manifest dependency to author, publish & consolidated for AEM Upgrade tools
- Add new parameters to author, publish & consolidated hiera file for AEM Upgrade automation
- Add Hiera configuration to enable feature truststore migration shinesolutions/aem-aws-stack-builder#229

### Changed
- Upgrade aem_curator to 1.4.0, aem_resources to 3.4.0
- The device name and device alias (aka attached device name) are now configurable via hieradata.

### Removed
- Move hiera parameter common::aws_region to aem-aws-stack-builder shinesolutions/aem-aws-stack-builder#187

## [3.3.1] - 2018-12-05

### Changed
- Extend components Inspec Test to test SSL communication for each port shinesolutions/aem-aws-stack-builder#225
- Provision readiness check script to all components

## [3.3.0] - 2018-11-29

### Added
- Add common::awslogs_service_name configuration property

### Changed
- Extend schedule snapshot script to un/schedule live snapshots shinesolutions/aem-aws-stack-builder#212
- Update Hiera configuration for Author & Consolidated to support SAML configuration
- Update Hiera configuration for Author & Consolidated to support creation of Truststore
- Update Hiera parameter naming for AEM HTTPS SSL keystore
- Renamed Consolidated offline-snapshot & offline-compaction-snapshot scripts shinesolutions/aem-aws-stack-builder#182
- Upgrade aem_curator to 1.3.0, aem_resources to 3.3.0

## [3.2.0] - 2018-10-22

### Added
- Add existing check of AEM pid file cq.pid before running offline-snapshot and offline-compaction #113
- Add InSpec checks to ensure java does not use OpenJDK
- Add configuration parameters for Chaos Monkey to configure component termination rule #122

### Changed
- Disable package management for simianarmy shinesolutions/puppet-simianarmy#6
- Enable InSpec test for Chaos Monkey
- Disable collectd-java plugin installation
- Update Hiera configuration for Author, Publish & Consolidated to support custom configuration Parameters for waiting until login page is ready. shinesolutions/aem-aws-stack-builder#184
- Improved logging for taking live/offline snapshot
- Upgrade aem_curator to 1.2.3, aem_resources to 3.2.1, simianarmy to 1.1.2

## [3.1.2] - 2018-08-12

### Changed
- Update aem_curator to 1.1.2 and aem_resources to 3.1.1

## [3.1.1] - 2018-08-08

### Changed
- Upgrade puppet-aem-curator to 1.1.1 to fix pre-6.4 config path for AEM Password Reset and AEM Health Check

## [3.1.0] - 2018-08-03

### Changed
- Update Hiera configuration for Author, Publish & Consolidated to support reconfiguring existing AEM installation
- Update Hiera configuration for Author, Publish & Consolidated to include parameters for System Users

## [3.0.2] - 2018-07-23

### Added
- Add Library puppet-aem to Puppetfile
- Add offline-snapshot and offline-compaction-snapshot feature for AEM Consolidated

### Changed
- Upgrade puppet-aem-curator to 1.0.3
- Rename all offline-snapshot, offline-compaction-snapshot related files with full-set suffix

## [3.0.1] - 2018-07-17

### Changed
- Fix deploy on init timeout
- Upgrade puppet-aem-curator to 1.0.2 for supporting non AEM OpenCloud extracted repositories

## [3.0.0] - 2018-07-07

### Changed
- Upgrade puppet-aem-resources to 3.x.x and puppet-aem-curator to 1.x.x for AEM 6.4 support

## [2.6.1] - 2018-07-09

### Added
- Add additional metrics to content health check for request latency and exceptions
- Added aws instance tags facts as variables in publish_dispatcher manifest for use in health check

### Changed
- Refactored content health check to add constants, simplify traverse_descriptor function, handling for internal URLs and support multiple metric submission
- Fix deploy on init timeout

## [2.6.0] - 2018-06-28

### Added
- Add content health check cron configuration

## [2.5.2] - 2018-06-14

### Added
- Add configurable chaos monkey settings

### Changed
- Set http_proxy and no_proxy to cron http support

## [2.5.1] - 2018-06-02

### Added
- Add hourly log rotation support
- Add cron http_proxy and no_proxy support

## [2.5.0] - 2018-05-31

### Added
- Add feature to make logrotation configurable for all AEM components
- Add Log directory /var/log/shinesolutions

### Changed
- Fix cron scheduled execution of offline snapshot and offline compaction snapshot by specifying message full path
- Enable publish launch configuration default to be set to the live or offline snapshot
- Upgrade Hiera configuration file to version 5

### Removed
- Moved schedule jobs log files to /var/log/shinesolutions

## [2.4.18] - 2018-05-19

### Changed
- Replace global SNS topic ARN with Stack Manager stack name class parameter
- Switch InSpec dependencies to released versions

## [2.4.17] - 2018-05-10

### Added
- Add scheduled jobs provisioning support

### Changed
- Fix undefined method lookup error on Chaos Monkey InSpec test #82

## [2.4.16] - 2018-05-07

### Added
- Add missing Puppet exit code translation after each Puppet apply

### Changed
- Fix Orchestrator InSpec test failure #70
- Fix export backup script parameters
- Clean up orphan volume when attaching new snapshot #59
- Modify scheduled jobs configuration to be feature based instead of component based

## [2.4.15] - 2018-04-26

### Changed
- Fix list packages missing config for consolidated
- Fix incorrect bucket variable on dispatcher artifacts deployment

## [2.4.14] - 2018-04-24

### Added
- Add enable_content_healthcheck configuration on AEM Publish-Dispatcher

### Changed
- Fix orphan volume following snapshot attachment #59

## [2.4.13] - 2018-04-20

### Added
- Add list packages AEM tool

### Changed
- Rename promoted AEM Author instance name for consistency with default naming convention
- Re-add dispatcher artifacts deployment to Author-Dispatcher and Publish-Dispatcher

## [2.4.12] - 2018-04-16

### Changed
- Fix Collectd CloudWatch regex matching

## [2.4.11] - 2018-04-13

### Changed
- Fix Collectd CloudWatch dimension so alarms can identify the metrics that belong to an EC2 instance
- Fix AEM Author Standby provisioner configuration

## [2.4.10] - 2018-04-12

### Added
- Add InSpec tests for aem-tools

## [2.4.9] - 2018-04-11

### Added
- Add readiness test for AEM Full-Set architecture in Orchestrator component
- Add export import backup(s) support, migrated from aem_curator

### Changed
- Fix AEM Package download and install due to missing template parameters
- Rename promoted Author Primary (from Author Standby) for clarity #64

## [2.4.8] - 2018-03-21

### Changed
- Fix dispatchers broken provisioning due to missing template parameter

## [2.4.7] - 2018-03-20

### Changed
- Clean up dispatcher template parameters in Hiera config

## [2.4.6] - 2018-03-15

### Added
- Add AEM Tools directory creation to component manifests

### Removed
- Move dispatcher docroot directory setting to Hiera config

## [2.4.5] - 2018-03-13

### Added
- Add Simian Army warfile source

## [2.4.4] - 2018-03-08

### Added
- Add flush dispatcher cache configuration

## [2.4.3] - 2018-03-03

### Added
- Add support to promote author standby as primary instance
- Add AEM ID tag to AMIs produced by live and offline snapshot backups #58

### Changed
- Modify passing of parameter docroot_dir

## [2.4.2] - 2018-02-06

### Changed
- Upgrade Puppet SimianArmy to 1.1.1 to handle empty proxy configuration

## [2.4.1] - 2018-02-02

### Changed
- Configure Collectd on author-primary, author-standby, publish, and author-publish-dispatcher components

## [2.4.0] - 2018-01-30

### Changed
- Fix incorrect publish hieradata for action_enable_crxde

### Removed
- Migrate artifacts deployment tools from aem-aws-stack-provisioner to aem_curator

## [2.3.0] - 2018-01-09

### Added
- Add multi devices support to live and offline snapshots
- Add multi AEM repository support to offline compaction
- Add multi AEM support to enable CRXDE
- Add support to disable CRXDE

### Removed
- Migrate all AEM Tools files and templates from aem-aws-stack-provisioner to aem_curator

## [2.2.1] - 2018-01-03

### Changed
- Localise global fact aem_orchestrator_version

## [2.2.0] - 2017-12-30

### Changed
- Modify author-primary, author-standby, publish, author-dispatcher, and publish-dispatcher to use aem_curator for provisioning

## [2.1.0] - 2017-12-20

### Added
- Add multi AEM instances support to artifact download and deploy #45
- Add static-assets deployment as part of AEM Dispatcher artifacts #47

### Changed
- Rename aem-tools script generate-artifacts-json.py to generate-artifacts-descriptor.py
- Rename artifacts deployment log to puppet-deploy-artifacts.log
- Replace Serverspec with InSpec for testing

## [2.0.0] - unknown

### Added
- Add provisioning for AuthorPublishDispatcher component

### Changed
- Lock down Puppet dependencies version
- TODO

### Removed
- Migrate provisioning code from manifests to puppet-aem-curator module

## [1.1.2] - 2017-07-28

### Changed
- Allow configurable volume type when attaching snapshot on publish instance

## [1.1.1] - 2017-06-07

### Changed
- Check instance is in correct state before entering or exiting standby

## [1.1.0] - 2017-06-02

### Added
- Add weekly offline compaction snapshot job to orchestrator

### Changed
- Make the offline snapshot time configurable
- Backup export should now clean up all versions of the package before exporting
- Set backup export timeout to 15 minutes

## [1.0.0] - 2017-05-22

### Added
- Initial version
