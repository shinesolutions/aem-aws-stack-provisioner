[![Build Status](https://github.com/shinesolutions/aem-aws-stack-provisioner/workflows/CI/badge.svg)](https://github.com/shinesolutions/aem-aws-stack-provisioner/actions?query=workflow%3ACI)
[![Known Vulnerabilities](https://snyk.io/test/github/shinesolutions/aem-aws-stack-provisioner/badge.svg)](https://snyk.io/test/github/shinesolutions/aem-aws-stack-provisioner)

# AEM AWS Stack Provisioner

AEM AWS Stack Provisioner is a Puppet provisioner for [AEM AWS Stack Builder](https://github.com/shinesolutions/aem-aws-stack-builder).

This library's artifact will be uploaded to S3 and retrieved by each EC2 instance stood up as part of an AEM environment creation using AEM AWS Stack Builder.
Each instance will then execute AEM AWS Stack Provisioner's component manifest as part of its cloud-init step, and the component InSpec test will be called at the end of cloud-init.

AEM AWS Stack Provisioner is currently a set of Puppet manifests, templates, configurations, and tests, where the corresponding component manifest will be applied directly. It is not (yet) used as a Puppet module.

AEM AWS Stack Provisioner is part of [AEM OpenCloud](https://aemopencloud.io) platform.

Learn more about AEM AWS Stack Provisioner:

* [Installation](#installation)
* [Usage](#usage)
* [Result Model](#result-model)
* [Error Handling](#error-handling)
* [Testing](#testing)
* [Versions History](#versions-history)
* [Frequently Asked Questions](https://github.com/shinesolutions/aem-aws-stack-provisioner/blob/main/docs/faq.md)

## Installation

Requirements on the instances:

* OpenVox 9 on Amazon Linux 2023 or Rocky Linux 10
* Cinc InSpec 7.2.1 on Ruby 4, which runs the [InSpec AEM AWS](https://github.com/shinesolutions/inspec-aem-aws) 4.0.0 profile included in the package
* Java 21 on the orchestrator instance, which runs AEM Orchestrator 5.0.0. Its jar is taken from the stack's data bucket,
  `s3://<data_bucket_name>/<stack_prefix>/aem-orchestrator-5.0.0.jar`, and verified against the SHA-256 checksum in `data/orchestrator.yaml`
* The AWS CLI, used by the scripts and to download the `s3://` sources

The package is a tarball of this repository with its dependencies, built with:

    make deps package

`make deps` installs the Puppetfile modules into `modules/` with r10k and downloads the InSpec AEM AWS profile from the URL in `inspec.yml`
into `files/test/inspec/inspec-aem-aws`. `make package` writes `stage/aem-aws-stack-provisioner-<version>.tar.gz`.
Released packages are attached to the [GitHub releases](https://github.com/shinesolutions/aem-aws-stack-provisioner/releases).

AEM AWS Stack Builder uploads the package to S3 for the instances. The manifests and `conf/hiera.yaml` expect it to be extracted to
`/opt/shinesolutions/aem-aws-stack-provisioner`.

## Usage

Each component of an AEM environment has a manifest in `manifests/`, applied with `puppet apply` using the modules in `modules/`
and the hiera configuration in `conf/hiera.yaml`, as the scripts in this repository do:

    puppet apply --modulepath modules --hiera_config conf/hiera.yaml manifests/<manifest>.pp

| Manifest | Applied on |
| --- | --- |
| `author-primary.pp`, `author-standby.pp`, `author-dispatcher.pp` | AEM Full-Set author primary, author standby and author dispatcher instances |
| `publish.pp`, `publish-dispatcher.pp` | AEM Full-Set publish and publish dispatcher instances |
| `preview-publish.pp`, `preview-publish-dispatcher.pp` | AEM Full-Set preview publish and preview publish dispatcher instances, when the preview architecture is enabled |
| `orchestrator.pp` | AEM Full-Set orchestrator instance |
| `chaos-monkey.pp` | AEM Full-Set Chaos Monkey instance, when Chaos Monkey is enabled |
| `author-publish-dispatcher.pp` | AEM Consolidated instance, with author, publish and dispatcher |
| `pre-common.pp` | Common setup shared by the components |
| `wait-until-ready.pp` | Waits until the AEM login page is ready and the AEM health check is OK |
| `action-scheduled-jobs.pp` | Scheduled jobs, applied by `schedule-snapshots.sh` and `promote-author-standby-to-primary.sh` |

The hiera data in `data/` is looked up in this order (see `conf/hiera.yaml`):

1. `data/<os family>/<os name>-<os major release>.yaml`, e.g. `data/RedHat/Amazon-2.yaml`
2. `data/<os family>/<os name>.yaml`
3. `data/local.yaml`, the user defined configuration, which is not part of this repository
4. `data/<event>.yaml`, from the `event` fact
5. `data/<component>.yaml`, from the `component` fact, e.g. `data/publish.yaml`
6. `data/common.yaml`

`aws-tools/set-facts.sh` sets the Facter facts that the manifests and hiera data use: the instance's EC2 tags, `data_bucket_name`,
and the stack facts from `s3://<data_bucket_name>/<stack_prefix>/stack-facts.txt`.

## Result Model

`pre-common.pp` results in:

* A host entry for the instance's FQDN and IP address, and the extra packages and SSH public keys from hiera
* The `aws-tools`, `aem-tools` and `common-tools` scripts in `/opt/shinesolutions`, including `aem-tools/test-readiness.sh` and the
  InSpec AEM AWS profile in `/opt/shinesolutions/aem-tools/test/inspec/inspec-aem-aws`
* The credentials file, downloaded from `s3://<data_bucket_name>/<stack_prefix>/` into `/tmp/shinesolutions/aem-aws-stack-provisioner`

The component manifests result in:

| Manifest | Results |
| --- | --- |
| `author-primary.pp`, `author-standby.pp`, `publish.pp`, `preview-publish.pp` | AEM configured by the [AEM Curator](https://github.com/shinesolutions/puppet-aem-curator) `aem_curator::config_*` classes, collectd and logrotate, the data volume resized, and the backup and snapshot scripts in `aem-tools` |
| `author-dispatcher.pp`, `publish-dispatcher.pp`, `preview-publish-dispatcher.pp` | AEM Dispatcher configured by AEM Curator, its artifacts deployed, the data volume resized, logrotate, and the `enter-standby.sh` and `exit-standby.sh` scripts |
| `author-publish-dispatcher.pp` | Author, publish and dispatcher configured by AEM Curator, the AEM packages and Dispatcher artifacts deployed, the data volumes resized, and the backup and snapshot scripts |
| `orchestrator.pp` | AEM Orchestrator installed by [puppet-aem-orchestrator](https://github.com/shinesolutions/puppet-aem-orchestrator), and the stack offline snapshot scripts and messages |
| `chaos-monkey.pp` | Chaos Monkey installed by [puppet-simianarmy](https://github.com/shinesolutions/puppet-simianarmy) |

`publish.pp` and `preview-publish.pp` first attach their repository volume from a snapshot when a snapshot ID is given.
`publish-dispatcher.pp` and `preview-publish-dispatcher.pp` also install `aem-tools/content-healthcheck.py`.
When the CloudWatch Logs agent configuration exists, the component manifests also prefix its log groups with the stack prefix and
its log streams with the component, and keep its service running.

The scripts that run Puppet use `--detailed-exitcodes`, and translate Puppet's exit codes to follow the usual convention:

| Puppet exit code | Meaning | Script exit code |
| --- | --- | --- |
| 0 | The run succeeded with no changes | 0 |
| 2 | The run succeeded with changes | 0 |
| 1, 4 or 6 | The run failed, or some resources failed | The same code |

## Error Handling

The Puppet run fails when:

* A class parameter without a default has no value in the hiera data, e.g. when `data/local.yaml` or the stack facts are missing
* A download from the data bucket fails, e.g. the credentials file or the AEM Orchestrator jar, or the jar doesn't match its checksum
* The InSpec AEM AWS profile is missing from the package, as `pre-common.pp` copies `files/test` to the instance

What isn't checked:

* Puppet doesn't check that AEM works; `wait-until-ready.pp` and the InSpec readiness test (`aem-tools/test-readiness.sh`) do.
  The readiness test runs from the orchestrator for AEM Full-Set; it isn't supported yet for AEM Consolidated
* The offline snapshot scripts stop AEM with `systemctl stop`. The AEM systemd unit has `TimeoutStopSec=4min`, so systemd kills AEM
  if a graceful stop takes longer
* `common-tools/run-adhoc-puppet.sh` runs with `errexit`, so a Puppet run with changes (exit code 2) exits with 2 before it's translated
* CI doesn't compile the catalogs or run the InSpec tests, as they need an AEM environment on AWS

## Testing

AEM AWS Stack Provisioner targets OpenVox 9 on Amazon Linux 2023 and Rocky Linux 10.

Run the commands below in [AEM Platform BuildEnv](https://github.com/shinesolutions/aem-platform-buildenv) (`shinesolutions/aem-platform-buildenv:6.4.1`), as CI does:

| Command | Runs |
| --- | --- |
| `make deps` | Install the Ruby gems with Bundler, the pinned Python tools into `.venv`, the Puppetfile modules into `modules/` with r10k, and the InSpec AEM AWS profile into `files/test/inspec/inspec-aem-aws` |
| `make deps-upgrade` | Upgrade the pinned Python dependencies in `requirements.txt` to the latest versions allowed by `requirements.in`, with pip-compile |
| `make rmdeps` | Remove the `.venv` venv |
| `make deps-local` | Replace the AEM OpenCloud Puppet modules in `modules/` with local checkouts next to this repository |
| `make lint` | puppet-lint, Puppet manifest and EPP template validation, ShellCheck, RuboCop, pylint, yamllint and markdownlint |
| `make test` | The Python unit tests of the `files/aws-tools` scripts, with AWS mocked by moto |
| `make package` | Package the provisioner into `stage/aem-aws-stack-provisioner-<version>.tar.gz` |
| `make ci` | Everything CI runs: clean, deps, lint, test and package |

The component InSpec tests in `test/inspec/` are run on the instances at the end of cloud-init.

## Versions History

See [CHANGELOG.md](CHANGELOG.md) for the changes in each version.

Releases are tagged `<version>` in git, with the package attached to the GitHub release. Between releases, the Makefile's `version`
holds the next pre-release version, e.g. `7.2.4-pre.0`. To release:

1. Check that the `## [Unreleased]` entries in CHANGELOG.md on `main` describe everything in this release.
2. In GitHub Actions, run the **Release Major**, **Release Minor** or **Release Patch** workflow. It uses
   [RTK](https://github.com/cliffano/rtk), configured in `.rtk.json`, to set the release version in the Makefile and CHANGELOG.md,
   commit and tag it `<version>`, commit the next pre-release version, and push the commits and the tag.
3. The pushed tag triggers the **Publish** workflow, which runs `make clean deps lint package publish` to create the GitHub release
   and upload the package.
