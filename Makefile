version ?= 7.2.4-pre.0

ci: clean deps lint test package

# Run a command in the Python venv created by deps
define python_venv
	. .venv/bin/activate && $(1)
endef

rmdeps:
	rm -rf .venv

# Gemfile.lock is committed and kept, so CI installs the pinned gems
clean:
	rm -rf modules stage vendor files/test

################################################################################
# Dependencies resolution targets.
# For deps-local target, the local dependencies must be
# available on the same directory level where aem-aws-stack-provisioner is at.
# The idea is that you can package AEM AWS Stack Provisioner for AEM AWS stack
# Builder testing while also developing those dependencies locally.
################################################################################

# resolve dependencies from remote artifact registries
# The InSpec AEM AWS profile (run on the instances by the aem-tools scripts with `inspec exec`) is
# downloaded from the URL in inspec.yml into files/test/inspec/inspec-aem-aws with curl and tar. This
# replaces `bundle exec inspec vendor`, which only downloaded and unpacked that same tarball, because the
# InSpec gem can't be used in this build any more:
# - InSpec 1.51.6 (the previous pin) doesn't load on Ruby 4
# - no InSpec version can share a bundle with OpenVox 9 (thor) or r10k 5 (faraday)
# - InSpec 5+ needs the Chef licence accepted, and 6/7 need licence keys
# The result is the same tree as before. InSpec is only needed at runtime on the instances, where
# inspec-aem-aws 4.0.0 expects Cinc InSpec 7.2.1 (an AMI requirement).
# It is saved to a file before extracting it, so a failed download (curl -f) fails the build instead of
# being hidden by a pipe; tar --no-same-owner, as root in the buildenv container can't chown files on a
# macOS bind mount.
# bundle install has no --binstubs option anymore in Bundler 4
# requirements-dev.txt is installed too, so lint runs the pinned pylint, which sees the venv's packages
deps:
	gem install bundler --version=4.0.22
	rm -rf .bundle
	bundle install
	python3 -m venv .venv
	$(call python_venv,python3 -m pip install -r requirements.txt -r requirements-dev.txt)
	bundle exec r10k puppetfile install --verbose --moduledir modules
	rm -rf vendor/inspec/ && mkdir -p vendor/inspec/
	curl -sSfL -o vendor/inspec/inspec-aem-aws.tar.gz "$$(ruby -ryaml -e "puts YAML.load_file('inspec.yml')['depends'][0]['url']")"
	tar --no-same-owner -xzf vendor/inspec/inspec-aem-aws.tar.gz -C vendor/inspec/
	rm vendor/inspec/inspec-aem-aws.tar.gz
	rm -rf files/test/inspec/ && mkdir -p files/test/inspec/
	mv vendor/inspec/inspec-aem-aws-* files/test/inspec/inspec-aem-aws

# Upgrade the Python dependencies in requirements.txt to the latest versions allowed by requirements.in
deps-upgrade:
	python3 -m venv .venv
	$(call python_venv,python3 -m pip install -r requirements-dev.txt)
	$(call python_venv,pip-compile --upgrade)

# resolve AEM OpenCloud's Puppet module dependencies from local directories
# TODO: include local InSpec modules
deps-local:
	rm -rf modules/aem_orchestrator/*
	rm -rf modules/aem_resources/*
	rm -rf modules/aem_curator/*
	rm -rf modules/simianarmy/*
	cp -R ../puppet-aem-orchestrator/* modules/aem_orchestrator/
	cp -R ../puppet-aem-resources/* modules/aem_resources/
	cp -R ../puppet-aem-curator/* modules/aem_curator/
	cp -R ../puppet-simianarmy/* modules/simianarmy/

# The puppet-lint checks added since puppet-lint 2.5.2 (mostly the Vox Pupuli
# plugins installed by voxpupuli-test) that report warnings on the manifests
# are disabled, from --no-exec_idempotency-check on, to keep the 2.5.2 checks,
# as fixing them needs code changes beyond the upgrade.
# yamllint runs with its default rules plus the repo-wide exceptions in .yamllint.yaml; file-specific
# exceptions are yamllint comments in the YAML files.
# markdownlint exceptions are inline comments too. CHANGELOG.md isn't linted, as rtk release
# rewrites it in its own layout.
# The checks that don't need the bundle run first, as they are the quickest to fail.
lint:
	shellcheck files/*/*.sh
	$(call python_venv,yamllint .yamllint.yaml .markdownlint.yaml .github/workflows/*.yaml .*.yml inspec.yml conf/*.yaml data/*.yaml data/*/*.yaml)
	markdownlint-cli2 README.md docs/*.md .github/ISSUE_TEMPLATE/*.md
	python3 -m json.tool .rtk.json
	$(call python_venv,pylint files/aws-tools/*.py files/aws-tools/route53-dns-alias-switch)
	bundle exec puppet-lint \
		--fail-on-warnings \
		--no-140chars-check \
		--no-autoloader_layout-check \
		--no-documentation-check \
		--no-only_variable_string-check \
		--no-selector_inside_resource-check \
		--no-variable_scope-check \
		--no-exec_idempotency-check \
		--no-file_ensure-check \
		--no-lookup_in_parameter-check \
		--no-manifest_whitespace_closing_brace_before-check \
		--no-manifest_whitespace_opening_brace_after-check \
		--no-parameter_documentation-check \
		--no-parameter_types-check \
		--no-strict_indent-check \
		--no-top_scope_facts-check \
		--no-trailing_comma-check \
		--log-format "%{path} (%{check}) L%{line} %{message}" \
		manifests/*.pp
	bundle exec puppet parser validate manifests/*.pp
	bundle exec puppet epp validate templates/*/*.epp
	bundle exec rubocop test/inspec/*.rb

# Run the Python unit tests of the aws-tools scripts, without writing __pycache__ into files/,
# which would end up in the package. The scripts create their boto3 clients without a region
# (boto3 reads AWS_DEFAULT_REGION, the test only sets AWS_REGION), so it is set to the test's region
test:
	$(call python_venv,AWS_DEFAULT_REGION=ap-southeast-2 PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -v -s files/aws-tools -p 'test_*.py')

# Package the working directory, then check the InSpec profile from deps is in it,
# as pre_common copies files/test to the instances. The .venv build tools are left out of it
package:
	rm -rf stage
	mkdir -p stage
	tar \
		--exclude='.git*' \
		--exclude='.tmp*' \
		--exclude='stage*' \
		--exclude='.idea*' \
		--exclude='.venv' \
		--exclude='.DS_Store*' \
		--exclude='*.tar' \
		-cvf \
		stage/aem-aws-stack-provisioner-$(version).tar ./
	gzip stage/aem-aws-stack-provisioner-$(version).tar
	tar -tzf stage/aem-aws-stack-provisioner-$(version).tar.gz ./files/test/inspec/inspec-aem-aws/inspec.yml

release-major:
	rtk release --release-increment-type major

release-minor:
	rtk release --release-increment-type minor

release-patch:
	rtk release --release-increment-type patch

release: release-minor

# Create the GitHub release and upload the package, run by the publish workflow on a pushed tag.
# safe.directory lets gh run git as root in the buildenv container
publish:
	GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0=$(CURDIR) \
		gh release create $(version) --title $(version) --notes "" || echo "Release $(version) has been created on GitHub"
	GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0=$(CURDIR) \
		gh release upload $(version) stage/aem-aws-stack-provisioner-$(version).tar.gz

.PHONY: ci rmdeps clean deps deps-upgrade deps-local lint test package release release-major release-minor release-patch publish
