### 2.5.0
* Fix cron scheduled execution of offline snapshot by specifying message full path
* Enable publish launch configuration default to be set to the live or offline snapshot
* Add feature to make logrotation configurable for all AEM components
* Add Log directory /var/log/shinesolutions
* Moved schedule jobs log files to /var/log/shinesolutions
* Upgrade Hiera configuration file to version 5

### 2.4.18
* Replace global SNS topic ARN with Stack Manager stack name class parameter
* Switch InSpec dependencies to released versions

### 2.4.17
* Fix undefined method lookup error on Chaos Monkey InSpec test #82
* Add scheduled jobs provisioning support

### 2.4.16
* Fix Orchestrator InSpec test failure #70
* Fix export backup script parameters
* Clean up orphan volume when attaching new snapshot #59
* Modify scheduled jobs configuration to be feature based instead of component based
* Add missing Puppet exit code translation after each Puppet apply

### 2.4.15
* Fix list packages missing config for consolidated
* Fix incorrect bucket variable on dispatcher artifacts deployment

### 2.4.14
* Add enable_content_healthcheck configuration on AEM Publish-Dispatcher
* Fix orphan volume following snapshot attachment #59

### 2.4.13
* Rename promoted AEM Author instance name for consistency with default naming convention
* Add list packages AEM tool
* Re-add dispatcher artifacts deployment to Author-Dispatcher and Publish-Dispatcher

### 2.4.12
* Fix Collectd CloudWatch regex matching

### 2.4.11
* Fix Collectd CloudWatch dimension so alarms can identify the metrics that belong to an EC2 instance
* Fix AEM Author Standby provisioner configuration

### 2.4.10
* Add InSpec tests for aem-tools

### 2.4.9
* Fix AEM Package download and install due to missing template parameters
* Rename promoted Author Primary (from Author Standby) for clarity #64
* Add readiness test for AEM Full-Set architecture in Orchestrator component
* Add export import backup(s) support, migrated from aem_curator

### 2.4.8
* Fix dispatchers broken provisioning due to missing template parameter

### 2.4.7
* Clean up dispatcher template parameters in Hiera config

### 2.4.6
* Add AEM Tools directory creation to component manifests
* Move dispatcher docroot directory setting to Hiera config

### 2.4.5
* Add Simian Army warfile source

### 2.4.4
* Add flush dispatcher cache configuration

### 2.4.3
* Add support to promote author standby as primary instance
* Add AEM ID tag to AMIs produced by live and offline snapshot backups #58
* Modify passing of parameter docroot_dir

### 2.4.2
* Upgrade Puppet SimianArmy to 1.1.1 to handle empty proxy configuration

### 2.4.1
* Configure Collectd on author-primary, author-standby, publish, and author-publish-dispatcher components

### 2.4.0
* Migrate artifacts deployment tools from aem-aws-stack-provisioner to aem_curator
* Fix incorrect publish hieradata for action_enable_crxde

### 2.3.0
* Migrate all AEM Tools files and templates from aem-aws-stack-provisioner to aem_curator
* Add multi devices support to live and offline snapshots
* Add multi AEM repository support to offline compaction
* Add multi AEM support to enable CRXDE
* Add support to disable CRXDE

### 2.2.1
* Localise global fact aem_orchestrator_version

### 2.2.0
* Modify author-primary, author-standby, publish, author-dispatcher, and publish-dispatcher to use aem_curator for provisioning

### 2.1.0
* Add multi AEM instances support to artifact download and deploy #45
* Rename aem-tools script generate-artifacts-json.py to generate-artifacts-descriptor.py
* Add static-assets deployment as part of AEM Dispatcher artifacts #47
* Rename artifacts deployment log to puppet-deploy-artifacts.log
* Replace Serverspec with InSpec for testing

### 2.0.0
* Migrate provisioning code from manifests to puppet-aem-curator module
* Add provisioning for AuthorPublishDispatcher component
* Lock down Puppet dependencies version
* TODO

### 1.1.2
* Allow configurable volume type when attaching snapshot on publish instance

### 1.1.1
* Check instance is in correct state before entering or exiting standby

### 1.1.0
* Add weekly offline compaction snapshot job to orchestrator
* Make the offline snapshot time configurable
* Backup export should now clean up all versions of the package before exporting
* Set backup export timeout to 15 minutes

### 1.0.0
* Initial version
