### 2.1.0
* Add multi AEM instances support to artifact download and deploy #45
* Rename aem-tools script generate-artifacts-json.py to generate-artifacts-descriptor.py
* Add static-assets deployment as part of AEM Dispatcher artifacts #47

### 2.0.0
* Migrate provisioning code from manifests to puppet-aem-curator module
* Add provisioning for AuthorPublishDispatcher component
* Lock down Puppet dependencies version

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
