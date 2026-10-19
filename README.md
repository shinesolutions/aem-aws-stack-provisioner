[![Build Status](https://github.com/shinesolutions/aem-aws-stack-provisioner/workflows/CI/badge.svg)](https://github.com/shinesolutions/aem-aws-stack-provisioner/actions?query=workflow%3ACI)
[![Known Vulnerabilities](https://snyk.io/test/github/shinesolutions/aem-aws-stack-provisioner/badge.svg)](https://snyk.io/test/github/shinesolutions/aem-aws-stack-provisioner)

AEM AWS Stack Provisioner
-------------------------

AEM AWS Stack Provisioner is a Puppet provisioner for [AEM AWS Stack Builder](https://github.com/shinesolutions/aem-aws-stack-builder).

This library's artifact will be uploaded to S3 and retrieved by each EC2 instance stood up as part of an AEM environment creation using AEM AWS Stack Builder.
Each instance will then execute AEM AWS Stack Provisioner's component manifest as part of its cloud-init step, and the component InSpec test will be called at the end of cloud-init.

AEM AWS Stack Provisioner is currently a set of Puppet manifests, templates, configurations, and tests, where the corresponding component manifest will be applied directly. It is not (yet) used as a Puppet module.

AEM AWS Stack Provisioner is part of [AEM OpenCloud](https://aemopencloud.io) platform.

Learn more about AEM AWS Stack Provisioner:

* [Frequently Asked Questions](https://github.com/shinesolutions/aem-aws-stack-provisioner/blob/main/docs/faq.md)

Development
-----------

AEM AWS Stack Provisioner targets OpenVox 9 on Amazon Linux 2023 and Rocky Linux 10.

Run the commands below in [AEM Platform BuildEnv](https://github.com/shinesolutions/aem-platform-buildenv), as CI does:

| Command | Runs |
| --- | --- |
| `make deps` | Install the Ruby gems with Bundler and the Puppetfile modules into `modules/` with r10k |
| `make deps-local` | Replace the AEM OpenCloud Puppet modules in `modules/` with local checkouts next to this repository |
| `make deps-inspec` | Vendor the InSpec profile dependencies from `inspec.yml` into `files/test/inspec/`, needs an InSpec CLI |
| `make lint` | puppet-lint, Puppet manifest and EPP template validation, ShellCheck, RuboCop, yamllint and markdownlint |
| `make package` | Package the provisioner into `stage/aem-aws-stack-provisioner-<version>.tar.gz` |
| `make ci` | Everything CI runs: clean, deps, lint and package |
