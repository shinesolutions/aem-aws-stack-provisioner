version ?= 7.2.4-pre.0

ci: clean deps lint package

clean:
	rm -rf .tmp Puppetfile.lock Gemfile.lock Gemfile.inspec.lock modules stage vendor files/test

################################################################################
# Dependencies resolution targets.
# For deps-local target, the local dependencies must be
# available on the same directory level where aem-aws-stack-provisioner is at.
# The idea is that you can package AEM AWS Stack Provisioner for AEM AWS stack
# Builder testing while also developing those dependencies locally.
################################################################################

# resolve dependencies from remote artifact registries
# InSpec has its own Gemfile.inspec because InSpec 7 (faraday 1) can't be
# bundled with r10k 5 (faraday 2). InSpec 7 vendors each profile already
# extracted under a <sha256> directory.
# aem_curator installed from git lacks its generated files/test InSpec profile
# (a Forge release includes it), so vendor it from aem_curator's inspec.yml.
deps:
	gem install bundler --version=4.0.22
	rm -rf .bundle
	bundle install -j4
	BUNDLE_GEMFILE=Gemfile.inspec bundle install -j4
	bundle exec r10k puppetfile install --verbose --moduledir modules
	BUNDLE_GEMFILE=Gemfile.inspec bundle exec inspec vendor --overwrite
	cd vendor && mv */inspec-aem-aws-*.*.* inspec-aem-aws
	cd vendor && find . -mindepth 1 -maxdepth 1 -type d ! -name inspec-aem-aws -exec rm -rf '{}' +
	rm -rf files/test/inspec/ && mkdir -p files/test/inspec/ && cp -R vendor/* files/test/inspec/
	if [ ! -d modules/aem_curator/files/test/inspec ]; then \
	  rm -rf .tmp/aem_curator_inspec && mkdir -p .tmp/aem_curator_inspec && \
	  cp modules/aem_curator/inspec.yml .tmp/aem_curator_inspec/ && \
	  BUNDLE_GEMFILE=Gemfile.inspec bundle exec inspec vendor --overwrite .tmp/aem_curator_inspec && \
	  mkdir -p modules/aem_curator/files/test/inspec && \
	  mv .tmp/aem_curator_inspec/vendor/*/inspec-aem-*.*.* modules/aem_curator/files/test/inspec/inspec-aem; \
	fi

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

lint:
	bundle exec puppet-lint \
		--fail-on-warnings \
		--no-140chars-check \
		--no-autoloader_layout-check \
		--no-documentation-check \
		--no-only_variable_string-check \
		--no-selector_inside_resource-check \
		--no-variable_scope-check \
		--log-format "%{path} (%{check}) L%{line} %{message}" \
		manifests/*.pp
	shellcheck files/*/*.sh
	bundle exec puppet parser validate manifests/*.pp
	bundle exec puppet epp validate templates/**/*.epp
	bundle exec rubocop test/inspec/*.rb
	bundle exec yaml-lint .*.yml conf/*.yaml data/*.yaml data/*/*.yaml

package:
	rm -rf stage
	mkdir -p stage
	tar \
		--exclude='.git*' \
		--exclude='.tmp*' \
		--exclude='stage*' \
		--exclude='.idea*' \
		--exclude='.DS_Store*' \
		--exclude='*.tar' \
		-cvf \
		stage/aem-aws-stack-provisioner-$(version).tar ./
	gzip stage/aem-aws-stack-provisioner-$(version).tar

release-major:
	rtk release --release-increment-type major

release-minor:
	rtk release --release-increment-type minor

release-patch:
	rtk release --release-increment-type patch

release: release-minor

publish:
	gh release create $(version) --title $(version) --notes "" || echo "Release $(version) has been created on GitHub"
	gh release upload $(version) stage/aem-aws-stack-provisioner-$(version).tar.gz

.PHONY: ci clean deps deps-local lint package release release-major release-minor release-patch publish
