version ?= 3.13.0

ci: clean deps lint package

clean:
	rm -rf .tmp Puppetfile.lock Gemfile.lock modules stage vendor files/test

################################################################################
# Dependencies resolution targets.
# For deps-local target, the local dependencies must be
# available on the same directory level where aem-aws-stack-provisioner is at.
# The idea is that you can package AEM AWS Stack Provisioner for AEM AWS stack
# Builder testing while also developing those dependencies locally.
################################################################################

# resolve dependencies from remote artifact registries
deps:
	gem install bundler
	bundle install --binstubs
	bundle exec r10k puppetfile install --verbose --moduledir modules
	bundle exec inspec vendor --overwrite
	cd vendor && find . -name "*.tar.gz" -exec tar -xzvf '{}' \; -exec rm '{}' \;
	cd vendor && mv inspec-aem-aws-*.*.* inspec-aem-aws
	rm -rf files/test/inspec/ && mkdir -p files/test/inspec/ && cp -R vendor/* files/test/inspec/
	# only needed while using shinesolutions/puppet-aem fork
	# TODO: remove when switching back to bstopp/puppet-aem
	rm -rf modules/aem/.git

# resolve AEM OpenCloud's Puppet module dependencies from local directories
# TODO: include local InSpec modules
deps-local:
	rm -rf modules/aem/*
	rm -rf modules/aem_orchestrator/*
	rm -rf modules/aem_resources/*
	rm -rf modules/aem_curator/*
	rm -rf modules/simianarmy/*
	cp -R ../puppet-aem/* modules/aem/
	cp -R ../puppet-aem-resources/* modules/aem_resources/
	cp -R ../puppet-aem-curator/* modules/aem_curator/
	cp -R ../puppet-simianarmy/* modules/simianarmy/
	# only needed while using shinesolutions/puppet-aem fork
	# TODO: remove when switching back to bstopp/puppet-aem
	rm -rf modules/aem/.git

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

release:
	rtk release

publish:
	putasset \
	  --owner shinesolutions \
	  --repo aem-aws-stack-provisioner \
	  --tag $(version) \
	  --filename stage/aem-aws-stack-provisioner-$(version).tar.gz \
	  --loud \
	  --show-url

.PHONY: ci clean deps deps-local lint package release publish
