# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [7.2.2] - 2024-09-16
### Changed
- Upgraded puppet-aem-curator to 4.1.7

## [7.2.1] - 2024-06-28
### Fixed
- Fixed tagging of snapshots from config #RS-165

## [7.2.0] - 2024-06-27
### Added
- Added tagging for snapshots from config #RS-165

## [7.1.1] - 2023-10-23

## [7.1.1] - 2023-10-23
### Changed
- Upgraded puppet-aem-curator to 4.1.6

## [7.1.0] - 2023-10-12
### Added
- Added aem_vlt_source, aem_vlt_version and vlt_dir config

### Changed
- Upgrade puppet-aem-curator to 4.1.3

## [7.0.4] - 2023-08-17
### Changed
- Upgrade puppet-aem-curator to 4.0.1
- Upgrade Puppet module puppet-aem-resources to 7.10.2

## [7.0.3] - 2023-08-16
### Fixed
- Fixed preview-publish component name in schedule-snapshot shell script

## [7.0.2] - 2023-08-16
### Fixed
- Fixed schedule-snapshot shell script for preview-publish

## [7.0.1] - 2023-08-07
### Changed
- Upgraded puppet-aem-curator to 4.0.0
- Upgrade puppet-aem-orchestrator to 2.0.1

## [7.0.0] - 2023-07-28
### Added
- Added provisioning manifests for preview Publish & preview publish-dispatcher RS-161

### Changed
- Upgrade inspec-aem-aws to 3.0.0

## [6.9.0] - 2023-07-26
### Changed
- Upgrade puppet-aem-curator to 3.41.0 #RS-166

## [6.8.1] - 2023-06-30
### Changed
- Upgraded puppet-aem-curator to 3.40.3

## [6.8.0] - 2023-06-07
### Changed
- Upgraded puppet-aem-curator to 3.38.0
- Upgrade Puppet module puppet-aem-resources to 7.10.1

## [6.7.0] - 2023-06-07
### Changed
- Upgraded puppet-aem-curator to 3.37.0
- Upgrade Puppet module puppet-aem-resources to 7.10.0

## [6.6.0] - 2023-06-03
### Changed
- Upgrade inspec-aem-aws to 2.6.0
- Upgraded puppet-aem-curator to 3.36.0
- Upgrade Puppet module puppet-aem-resources to 7.9.0

## [6.5.1] - 2023-04-27
### Changed
- CloudWatch Logs agent to start after files are reconfigured #RS-143

## [6.5.0] - 2023-04-21
### Changed
- Upgraded puppet-aem-curator to `3.35.0` #RS-142

## [6.4.1] - 2023-03-24
### Fixed
- Revert removal of default Apache httpd files introduced in RS-138 #RS-139

## [6.4.0] - 2023-03-03
### Changed
- Changed aem service management to systemd #RS-40
- Upgraded puppet-aem-curator to `3.34.0` #RS-40

## [6.3.0] - 2023-03-01
### Added
- Add removal of default Apache httpd files in pre_common to ensure it's not correlating with the configuration files from AMI Baking & Package deployment#RS-138

### Changed
- Upgraded puppet-aem-curator to `3.33.2` #RS-40

## [6.2.1] - 2023-02-17
### Changed
- Upgraded puppet-aem-curator to `3.33.1` #RS-125

### Fixed
- Fixed syntax error in `action_promote_author_standby_to_primary` #RS-125

## [6.2.0] - 2023-02-15
### Added
- Added hiera parameters to enable authentication for JMX on AEM Author & AEM Publish  #RS-125

### Changed
- Upgraded puppet-aem-curator to `3.33.0` #RS-125

## [6.1.1] - 2023-02-14
### Fixed
- Update puppet-aem-curator version in Puppetfile to `3.32.0` #RS-124

## [6.1.0] - 2023-02-10
### Added
- Added hiera parameters to enabale SSL for JMX for AEM Author & AEM Publish  #RS-124

### Changed
- Lockdowned version of `concurrent-ruby` to `1.1.9` #RS-126
- Upgraded puppet-aem-curator to `3.32.0` #RS-124

## [6.0.0] - 2023-01-29
### Changed
- Replace script to update the snapshot id in launch configuration with script to update snapshot id in launch template

## [5.11.0] - 2022-10-25
### Added
- Added configurable port and protocol of publish replication agent for consolidated env.

## [5.10.0] - 2022-08-31
### Changed
- Upgrade Puppet module `puppet/archive` to `6.0.2`
- Upgrade Puppet module `puppet-collectd` to `13.0.0`
- Upgrade Puppet module `puppetlabs/concat` to `7.2.0`
- Upgrade Puppet module `puppet-healthcheck` to `1.0.1`
- Upgrade Puppet module `puppet-logrotate` to `6.1.0`
- Upgrade Puppet module `puppetlabs/java` to `8.2.0`
- Upgrade Puppet module `puppetlabs/java_ks` to `4.3.1`
- Upgrade Puppet module `puppetlabs/stdlib` to `8.4.0`
- Upgrade Puppet module `puppet-yum` to `6.0.0`
- Upgrade Puppet module `shinesolutions/aem_resources` to `7.6.1`
- Upgrade ruby dependencies to most recent working version
- Upgrade puppet-aem-curator to 3.29.0
- Update Github Action Publish Docker image to `shinesolutions/aem-platform-buildenv:3.1.0`
- Update Gemfile with missing dependencies

## [5.9.3] - 2022-03-11
### Changed
- Upgrade puppet-aem-curator to 3.27.0

## [5.9.2] - 2022-03-01
### Changed
- Upgrade puppet-aem-curator to 3.26.0

## [5.9.1] - 2022-02-25
### Changed
- Upgrade puppet-aem-curator to 3.25.0

## [5.9.0] - 2022-02-14
### Fixed
- Fix race condition of multiple Publishers using the update_snapshot_id_in_launch_conf.py script [#236]

## [5.8.2] - 2022-02-04
### Changed
- Upgrade inspec-aem-aws to 2.4.0

## [5.8.1] - 2022-02-02
### Fixed
- Fix content-healthcheck.py.epp by setting protocol to https and port 5433

## [5.8.0] - 2021-12-02
### Changed
- Upgrade inspec-aem-aws to 2.3.0

## [5.7.0] - 2021-11-22
### Changed
- Upgrade puppet-aem-curator to 3.23.0
- Upgrade puppet-aem-resources to 7.5.0
- Upgrade inspec-aem-aws to 2.2.0

## [5.6.0] - 2021-11-19
### Changed
- Upgrade inspec-aem-aws to 2.1.0

## [5.5.1] - 2021-11-17
### Added
- Added FAQ section

### Fixed
- Fix Author Publish Dispatcher's deploy on init timeout variable not being propagated

## [5.5.0] - 2021-10-26
### Changed
- Upgrade inspec-aem-aws to 2.0.2

## [5.4.0] - 2021-10-26
### Added
- Add release-major, release-minor, release-patch, and publish Makefile targets and GitHub Actions

### Changed
- Upgrade puppet-aem-curator to 3.22.0
- Upgrade puppet-aem-resources to 7.4.0
- Modify publish target, replace putasset with gh CLI

## [5.3.0] - 2021-06-18
### Changed
- Upgrade puppet-aem-curator to 3.20.0

## [5.2.0] - 2021-04-29
### Changed
- Upgrade puppet-aem-curator to 3.19.0

## [5.1.0] - 2021-03-02
### Changed
- Convert python scripts to be executed using Python 3

## [5.0.0] - 2020-11-30
### Changed
- Change orchestrator application setting to HTTPS [#220]
- Upgrade puppet-aem-resources to 7.2.1
- Upgrade puppet-aem-curator to 3.18.1
- Upgrade AEM Orchestrator to 3.0.0 [#225]
- Upgrade inspec-aem-aws to 2.0.0

## [4.38.0] - 2020-09-27
### Changed
- Upgrade puppet-aem-resources to 7.2.0
- Upgrade puppet-aem-curator to 3.16.0

## [4.37.0] - 2020-09-14
### Changed
- Upgrade puppet-aem-resources to 7.1.0
- Upgrade puppet-aem-curator to 3.15.0

### Removed
- Removed SSL verification test for Author-Standby [shinesolutions/puppet-aem-curator#220]

## [4.36.2] - 2020-05-13
### Changed
- Upgrade puppet-aem-curator to 3.13.2
- Upgrade puppet-aem-resources to 7.0.1

### Fixed
- Fixed missing hiera parameters

## [4.36.1] - 2020-05-12
### Changed
- Upgrade puppet-aem-curator to 3.13.1

## [4.36.0] - 2020-05-12
### Changed
- Upgrade puppet-aem-curator to 3.13.0
- Upgrade puppet-aem-resources to 7.0.0

## [4.35.0] - 2020-05-12
### Added
- Add new hiera parameters to support new puppet-aem-curator version

### Changed
- Upgrade puppet-aem-curator to 3.12.0
- Upgrade puppet-aem-resources to 6.0.0

## [4.34.0] - 2020-04-05
### Added
- Add support `aws_region` support to cloud scripts [shinesolutions/aem-opencloud-manager#65]

### Changed
- Changed author-publish-dispatcher replication agent to https [#212]
- Upgrade puppet-aem-curator to 3.11.0

## [4.33.0] - 2020-03-19
### Changed
- Upgrade puppet-aem-curator to 3.10.1

## [4.32.0] - 2020-03-18
### Changed
- Upgrade puppet-aem-curator to 3.10.0

## [4.31.0] - 2020-03-06
### Changed
- Add support for multi hours in the live-snaphsot scheduler

## [4.29.0] - 2020-03-01
### Added
- Add awslogs.lock file removal to ensure awslogs nanny script does not start the service
- Add support for Dispatcher data volume [shinesolutions/aem-aws-stack-builder#379]
- Add hiera parameter to enable aem directory cleanup while provisioning

### Changed
- Set exec timeout for attaching publish snapshot to the EC2 instance to `0`
- Increase `snapshot_attach` timeout to 4h
- Increase `snapshot_backup` timeout to 4h
- Increase `wait_for_ec2tags` timeout to 720 retries
- Upgrade inspec-aem-aws to 1.10.0
- Upgrade puppet-aem-curator to 3.9.0

### Removed
- Remove parameter `snapshot_attach_timeout` in publish manifest

## [4.28.0] - 2020-01-28
### Changed
- Upgrade puppet-aem-curator to 3.8.0

### Fixed
- Fix issue with the interaction of the aws-sdk on the OS [#205]

## [4.27.0] - 2019-12-22
### Added
- Added new hiera parameter `enable_aem_installation_migration` [shinesolutions/puppet-aem-curator#167]

### Changed
- Upgrade puppet-aem-curator to 3.6.0

### Removed
- Clean up CloudWatch Metric Agent ASG metadata created from AMI baking

## [4.26.0] - 2019-12-15
### Changed
- Upgrade puppet-aem-curator to 3.5.0
- Upgrade puppet-aem-resources to 5.3.0
- Enable awslogs on pre-common step for all components [shinesolutions/packer-aem#192]

## [4.25.0] - 2019-12-02
### Changed
- Upgrade puppet-aem-resources to 5.2.0

## [4.24.0] - 2019-12-01
### Changed
- Upgrade puppet-aem-curator to 3.4.0

## [4.23.0] - 2019-12-01
### Removed
- Remove puppet-aem local provisioning in Makefile deps-local target due  to the switch back to bstopp/puppet-aem in aem-aws-stack-provisioner 4.7.0

## [4.22.0] - 2019-11-28
### Changed
- Upgrade puppet-aem-resources to 5.1.0

## [4.21.0] - 2019-11-27
### Added
- Added new hiera parameter `enable_remove_all_agents` with default value `true` to enable the removal of all AEM agents while configuring `author-primary` & `publish` [shinesolutions/puppet-aem-curator#149] [shinesolutions/puppet-aem-curator#150]
- Added new hiera parameter `enable_create_flush_agents` with default value `true` to enable creation of the dispatcher flush agents while configuring `publish` [shinesolutions/puppet-aem-curator#149] [shinesolutions/puppet-aem-curator#150]
- Added new hiera parameter `enable_create_outbox_replication_agents` with default value `true` to enable creation of the dispatcher replication agents while configuring `publish` [shinesolutions/puppet-aem-curator#149] [shinesolutions/puppet-aem-curator#150]
- Resize data volume on AEM Author and Publish in order to handle data volume in the AEM instances is larger than that set in the AMI

### Changed
- Upgrade puppet-aem-curator to 3.3.0
- Renamed hiera parameter for resolving the aem_system_users from `common::aem_system_users` to component specific hiera parameter `[author|publish]::aem_system_users` [shinesolutions/aem-aws-stack-builder#352]
- Upgrade inspec-aem-aws to 1.10.0

## [4.20.1] - 2019-10-17
### Changed
- Upgrade puppet-aem-curator to 3.0.1

### Fixed
- Fixed bug when provisioning aem upgrade tools [#196]

## [4.20.0] - 2019-10-16
### Added
- Add check if awslogs is installed to skip awslogs specific tasks [shinesolutions/aem-aws-stack-builder#333]

### Changed
- Disable logrotation for awslogs logfiles on publisher during snapshot_attach process [#194]
- Replaced reconfiguration hiera parameter `cert_base` with new paremeters
- Upgrade puppet-aem-curator to 3.0.0, puppet-aem-resources to 5.0.0

### Removed
- Removed hiera configuration for deprecated reconfiguration parameter `enable_create_system_users`

## [4.19.0] - 2019-10-07
### Changed
- Increase snapshot waiting timeout to 1 hour in snapshot_backup.py to handle encrypted volume

## [4.18.0] - 2019-10-01
### Changed
- Rename cloudwatch_s3_Stream param to cloudwatch_s3_stream

## [4.17.0] - 2019-09-20
### Added
- Add new CronJob to subscribe all Cloudwatch log groups of the stack to the provided Lambda function

## [4.16.0] - 2019-09-10
### Added
- Added new hiera parameter for component author-standby [shinesolutions/puppet-aem-curator#141]
- Add inspec check to ensure Simian Army log is created

### Changed
- Upgrade puppet-aem-curator to 2.10.0

### Fixed
- Fix webapps permission for tomcat user which caused Simian Army webapp not getting started by Tomcat app

## [4.15.0] - 2019-09-07
### Fixed
- Fixed error while disabling awslogs daemon cronjobs to prevent awslogs from restart [shinesolutions/aem-aws-stack-builder#311]

## [4.14.0] - 2019-09-07
### Added
- Add feature to deploy defined users SSH Public Key on the EC instances shinesolutions/aem-aws-stack-builder#313

## [4.13.0] - 2019-08-16
### Added
- Add new Hiera parameters for Aem-healthcheck-content package installation shinesolutions/puppet-aem-curator#181

### Changed
- Change wait_for_ec2tags total retry timeout to 30 minutes
- Upgrade puppet-aem-curator to 2.9.0

## [4.12.0] - 2019-08-15
### Changed
- Upgrade puppet-aem-curator to 2.8.0

## [4.11.0] - 2019-08-15
### Changed
- Upgrade puppet-aem-curator to 2.8.0

## [4.10.0] - 2019-08-14
### Changed
- Update test-readiness to use the new provisioning-readiness test [#178]
- Upgrade inspec-aem-aws to 1.3.0

## [4.9.0] - 2019-08-08
### Changed
- Increase snapshot waiting timeout to 1 hour in snapshot_attach.py to handle 500Gb EBS volume

### Fixed
- Fix description on stopping awslogs service prior to attaching snapshot volume

## [4.8.0] - 2019-08-05
### Added
- Add publish::snapshot_attach_timeout parameter defaults to 900 seconds

## [4.7.0] - 2019-07-23
### Changed
- Upgrade puppet-aem-curator to 2.6.0
- Upgrade puppet-aem to 3.0.0

## [4.6.0] - 2019-07-19
### Added
- Add new hiera fact for action_enable_saml

### Changed
- Upgrade puppet-aem-curator to 2.4.0
- Upgrade puppet-aem-resources to 4.1.0

## [4.5.0] - 2019-07-01
### Changed
- Upgrade puppet-aem-curator to 2.3.0
- Parameterise Dispatcher artifacts deployment timeout, defaults to 15 minutes
- Parameterise Author-Publish-Dispatcher artifacts deployment timeout, defaults to 0 due to possibility of extremely large AEM packages

## [4.3.0] - 2019-06-14
### Added
- Extend readiness check to check FS stacks with disabled chaos monkey shinesolutions/aem-aws-stack-builder#290

### Changed
- Upgrade inspec-aem-aws to 1.1.0
- Upgrade puppet-aem-curator to 2.0.0
- Upgrade puppet-aem-resources to 4.0.0

### Fixed
- Fix cron environment variables (create dummy job that adds proxy environment variables once only).  Address issue [#171]

## [4.2.0] - 2019-05-23
### Changed
- Upgrade inspec-aem-aws to 1.0.0

## [4.1.0] - 2019-05-22
### Changed
- awslogs service disable prior to snapshot attaching should now be non-blocking
- Upgrade puppet-aem-curator to 1.25.0

## [4.0.0] - 2019-05-22
### Added
- Add new component tag ComponentInitStatus in wait_for_ec2tags.py

### Changed
- Increased timeout for wait_for_ec2tags.py to 15 minutes

## [3.18.0] - 2019-05-22
### Changed
- Upgrade puppet-aem-curator to 1.24.1
- Upgrade puppet-aem-resources to 3.10.1
- Upgrade puppet-simianarmy to 1.1.4
- Upgrade inspec-aem-aws to 0.14.1
- Lock down dependencies versions

## [3.17.0] - 2019-05-03
### Changed
- Upgrade puppet-aem-curator to 1.23.0

## [3.16.0] - 2019-04-17
### Changed
- Upgrade puppet-aem-curator to 1.22.0, puppet-aem-resources to 3.10.0

### Fixed
- Fix parameter passing for action_promote_author_standby_to_primary

## [3.15.0] - 2019-04-07
### Changed
- Upgrade puppet-aem-curator to 1.21.0

## [3.14.0] - 2019-04-04
### Fixed
- Fixed failure with disabling awslogs cronjobs when config doesn't exist

## [3.13.0] - 2019-04-03
### Added
- Temporary disabling all awslogs cronjobs during publisher provisioning

### Changed
- Upgrade inspec-aem-aws to 0.13.0 for executing inspec outside of bundler

### Fixed
- Fix parameter passing for awslogs service name when provision publish instance

## [3.12.1] - 2019-04-02
### Fixed
- Fix AEM Author and AEM Publish symlink to check installation path instead of repository path

## [3.12.0] - 2019-04-02
### Added
- Setting default value for data_volume_mount_point parameter, needed for reconfiguration.

### Changed
- Extend the relationship around mounting the publish snapshot to the OS
- Upgrade inspec-aem-aws to 0.12.0
- Upgrade puppet-aem-curator to 1.20.0, puppet-aem-resources to 3.9.0
- Changed the aws-tools/promote-author-standby-to-primary.sh to check the exit codes of all commands it executes [#155]
- Pass hiera parameters for promote-author-standby-to-primary.sh

## [3.11.0] - 2019-03-21
### Changed
- Upgrade puppet-aem-curator to 1.18.0

## [3.10.0] - 2019-03-20
### Changed
- Upgrade puppet-aem-curator to 1.17.0

## [3.9.0] - 2019-03-19
### Changed
- Manage AEM Orchestrator directories permission and ownership shinesolutions/aem-aws-stack-builder#269
- Manage Simian Army directories permission and ownership shinesolutions/aem-aws-stack-builder#268
- Upgrade puppet-aem-orchestrator to 1.4.0, puppet-simianarmy to 1.1.3

## [3.8.0] - 2019-03-15
### Added
- Install AEM Health Check package as part of AEM start up to handle repository without the package or with an older version of the package

### Changed
- Upgrade aem_curator to 1.14.0

### Removed
- Remove example descriptors since they have been migrated to aem-helloworld-config

## [3.7.0] - 2019-03-13
### Added
- Add more author, publish, and orchestrator tests

### Changed
- Improved offline-snpahost & offline-compaction-snapshot for consolidated [#153]
- Upgrade aem_curator to 1.13.0

## [3.6.0] - 2019-02-16
### Added
- Add new parameter to remove the AEM Global Trusttore during reconfiguration

### Changed
- Renamed proxy_exceptions parameter to proxy_noproxy
- Upgrade aem_curator to 1.11.0, aem_resources to 3.8.0
- Fix failing snapshot by increasing the max_attempts for boto3 client to 120 tries [#121]

## [3.5.0] - 2019-02-03
### Changed
- Upgrade aem_curator to 1.9.0, aem_resources to 3.6.0

## [3.4.0] - 2019-01-29
### Added
- Add new manifest dependency to author, publish & consolidated for AEM Upgrade tools
- Add new parameters to author, publish & consolidated hiera file for AEM Upgrade automation
- Add Hiera configuration to enable feature truststore migration shinesolutions/aem-aws-stack-builder#229
- Add proxy configuration for configuring AEM Bundle Apache HTTP Components Proxy Configuration shinesolutions/aem-aws-stack-builder#235
- Add parameters for post start sleep timer to give the AEM service more time to start before configuring AEM shinesolutions/aem-aws-stack-builder#214

### Changed
- Upgrade aem_curator to 1.4.0, aem_resources to 3.4.0, aem_orchestrator to 1.3.1
- The device name and device alias (aka attached device name) are now configurable via hieradata.
- Add missing parameter tmp_dir passing for AEM Author & Publish components

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
- Add existing check of AEM pid file cq.pid before running offline-snapshot and offline-compaction [#113]
- Add InSpec checks to ensure java does not use OpenJDK
- Add configuration parameters for Chaos Monkey to configure component termination rule [#122]

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
- Fix undefined method lookup error on Chaos Monkey InSpec test [#82]

## [2.4.16] - 2018-05-07
### Added
- Add missing Puppet exit code translation after each Puppet apply

### Changed
- Fix Orchestrator InSpec test failure [#70]
- Fix export backup script parameters
- Clean up orphan volume when attaching new snapshot [#59]
- Modify scheduled jobs configuration to be feature based instead of component based

## [2.4.15] - 2018-04-26
### Changed
- Fix list packages missing config for consolidated
- Fix incorrect bucket variable on dispatcher artifacts deployment

## [2.4.14] - 2018-04-24
### Added
- Add enable_content_healthcheck configuration on AEM Publish-Dispatcher

### Changed
- Fix orphan volume following snapshot attachment [#59]

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
- Rename promoted Author Primary (from Author Standby) for clarity [#64]

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
- Add AEM ID tag to AMIs produced by live and offline snapshot backups [#58]

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
- Add multi AEM instances support to artifact download and deploy [#45]
- Add static-assets deployment as part of AEM Dispatcher artifacts [#47]

### Changed
- Rename aem-tools script generate-artifacts-json.py to generate-artifacts-descriptor.py
- Rename artifacts deployment log to puppet-deploy-artifacts.log
- Replace Serverspec with InSpec for testing

## [2.0.0] - 2017-08-01
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

## 1.0.0 - 2017-05-22
### Added
- Initial version

[#45]: https://github.com/shinesolutions/aem-aws-stack-provisioner/issues/45
[#47]: https://github.com/shinesolutions/aem-aws-stack-provisioner/issues/47
[#58]: https://github.com/shinesolutions/aem-aws-stack-provisioner/issues/58
[#59]: https://github.com/shinesolutions/aem-aws-stack-provisioner/issues/59
[#64]: https://github.com/shinesolutions/aem-aws-stack-provisioner/issues/64
[#70]: https://github.com/shinesolutions/aem-aws-stack-provisioner/issues/70
[#82]: https://github.com/shinesolutions/aem-aws-stack-provisioner/issues/82
[#113]: https://github.com/shinesolutions/aem-aws-stack-provisioner/issues/113
[#121]: https://github.com/shinesolutions/aem-aws-stack-provisioner/issues/121
[#122]: https://github.com/shinesolutions/aem-aws-stack-provisioner/issues/122
[#153]: https://github.com/shinesolutions/aem-aws-stack-provisioner/issues/153
[#155]: https://github.com/shinesolutions/aem-aws-stack-provisioner/issues/155
[#171]: https://github.com/shinesolutions/aem-aws-stack-provisioner/issues/171
[#178]: https://github.com/shinesolutions/aem-aws-stack-provisioner/issues/178
[#194]: https://github.com/shinesolutions/aem-aws-stack-provisioner/issues/194
[#196]: https://github.com/shinesolutions/aem-aws-stack-provisioner/issues/196
[#205]: https://github.com/shinesolutions/aem-aws-stack-provisioner/issues/205
[#212]: https://github.com/shinesolutions/aem-aws-stack-provisioner/issues/212
[#220]: https://github.com/shinesolutions/aem-aws-stack-provisioner/issues/220
[#225]: https://github.com/shinesolutions/aem-aws-stack-provisioner/issues/225
[#236]: https://github.com/shinesolutions/aem-aws-stack-provisioner/issues/236

[Unreleased]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/7.2.2...HEAD
[7.2.2]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/7.2.1...7.2.2
[7.2.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/7.2.0...7.2.1
[7.2.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/7.1.1...7.2.0
[7.1.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/7.1.1...7.1.1
[7.1.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/7.1.0...7.1.1
[7.1.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/7.0.4...7.1.0
[7.0.4]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/7.0.3...7.0.4
[7.0.3]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/7.0.2...7.0.3
[7.0.2]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/7.0.1...7.0.2
[7.0.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/7.0.0...7.0.1
[7.0.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/6.9.0...7.0.0
[6.9.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/6.8.1...6.9.0
[6.8.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/6.8.0...6.8.1
[6.8.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/6.7.0...6.8.0
[6.7.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/6.6.0...6.7.0
[6.6.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/6.5.1...6.6.0
[6.5.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/6.5.0...6.5.1
[6.5.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/6.4.1...6.5.0
[6.4.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/6.4.0...6.4.1
[6.4.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/6.3.0...6.4.0
[6.3.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/6.2.1...6.3.0
[6.2.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/6.2.0...6.2.1
[6.2.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/6.1.1...6.2.0
[6.1.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/6.1.0...6.1.1
[6.1.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/6.0.0...6.1.0
[6.0.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/5.11.0...6.0.0
[5.11.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/5.10.0...5.11.0
[5.10.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/5.9.3...5.10.0
[5.9.3]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/5.9.2...5.9.3
[5.9.2]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/5.9.1...5.9.2
[5.9.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/5.9.0...5.9.1
[5.9.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/5.8.2...5.9.0
[5.8.2]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/5.8.1...5.8.2
[5.8.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/5.8.0...5.8.1
[5.8.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/5.7.0...5.8.0
[5.7.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/5.6.0...5.7.0
[5.6.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/5.5.1...5.6.0
[5.5.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/5.5.0...5.5.1
[5.5.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/5.4.0...5.5.0
[5.4.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/5.3.0...5.4.0
[5.3.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/5.2.0...5.3.0
[5.2.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/5.1.0...5.2.0
[5.1.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/5.0.0...5.1.0
[5.0.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.38.0...5.0.0
[4.38.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.37.0...4.38.0
[4.37.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.36.2...4.37.0
[4.36.2]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.36.1...4.36.2
[4.36.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.36.0...4.36.1
[4.36.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.35.0...4.36.0
[4.35.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.34.0...4.35.0
[4.34.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.33.0...4.34.0
[4.33.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.32.0...4.33.0
[4.32.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.31.0...4.32.0
[4.31.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.29.0...4.31.0
[4.29.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.28.0...4.29.0
[4.28.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.27.0...4.28.0
[4.27.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.26.0...4.27.0
[4.26.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.25.0...4.26.0
[4.25.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.24.0...4.25.0
[4.24.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.23.0...4.24.0
[4.23.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.22.0...4.23.0
[4.22.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.21.0...4.22.0
[4.21.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.20.1...4.21.0
[4.20.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.20.0...4.20.1
[4.20.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.19.0...4.20.0
[4.19.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.18.0...4.19.0
[4.18.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.17.0...4.18.0
[4.17.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.16.0...4.17.0
[4.16.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.15.0...4.16.0
[4.15.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.14.0...4.15.0
[4.14.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.13.0...4.14.0
[4.13.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.12.0...4.13.0
[4.12.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.11.0...4.12.0
[4.11.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.10.0...4.11.0
[4.10.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.9.0...4.10.0
[4.9.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.8.0...4.9.0
[4.8.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.7.0...4.8.0
[4.7.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.6.0...4.7.0
[4.6.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.5.0...4.6.0
[4.5.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.3.0...4.5.0
[4.3.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.2.0...4.3.0
[4.2.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.1.0...4.2.0
[4.1.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/4.0.0...4.1.0
[4.0.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.18.0...4.0.0
[3.18.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.17.0...3.18.0
[3.17.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.16.0...3.17.0
[3.16.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.15.0...3.16.0
[3.15.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.14.0...3.15.0
[3.14.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.13.0...3.14.0
[3.13.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.12.1...3.13.0
[3.12.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.12.0...3.12.1
[3.12.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.11.0...3.12.0
[3.11.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.10.0...3.11.0
[3.10.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.9.0...3.10.0
[3.9.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.8.0...3.9.0
[3.8.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.7.0...3.8.0
[3.7.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.6.0...3.7.0
[3.6.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.5.0...3.6.0
[3.5.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.4.0...3.5.0
[3.4.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.3.1...3.4.0
[3.3.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.3.0...3.3.1
[3.3.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.2.0...3.3.0
[3.2.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.1.2...3.2.0
[3.1.2]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.1.1...3.1.2
[3.1.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.1.0...3.1.1
[3.1.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.0.2...3.1.0
[3.0.2]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.0.1...3.0.2
[3.0.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/3.0.0...3.0.1
[3.0.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.6.1...3.0.0
[2.6.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.6.0...2.6.1
[2.6.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.5.2...2.6.0
[2.5.2]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.5.1...2.5.2
[2.5.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.5.0...2.5.1
[2.5.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.4.18...2.5.0
[2.4.18]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.4.17...2.4.18
[2.4.17]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.4.16...2.4.17
[2.4.16]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.4.15...2.4.16
[2.4.15]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.4.14...2.4.15
[2.4.14]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.4.13...2.4.14
[2.4.13]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.4.12...2.4.13
[2.4.12]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.4.11...2.4.12
[2.4.11]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.4.10...2.4.11
[2.4.10]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.4.9...2.4.10
[2.4.9]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.4.8...2.4.9
[2.4.8]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.4.7...2.4.8
[2.4.7]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.4.6...2.4.7
[2.4.6]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.4.5...2.4.6
[2.4.5]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.4.4...2.4.5
[2.4.4]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.4.3...2.4.4
[2.4.3]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.4.2...2.4.3
[2.4.2]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.4.1...2.4.2
[2.4.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.4.0...2.4.1
[2.4.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.3.0...2.4.0
[2.3.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.2.1...2.3.0
[2.2.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.2.0...2.2.1
[2.2.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.1.0...2.2.0
[2.1.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/1.1.2...2.0.0
[1.1.2]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/1.1.1...1.1.2
[1.1.1]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/1.1.0...1.1.1
[1.1.0]: https://github.com/shinesolutions/aem-aws-stack-provisioner/compare/1.0.0...1.1.0
