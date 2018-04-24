version ?= 2.4.15

ci: clean deps lint validate package

clean:
	rm -rf .tmp Puppetfile.lock Gemfile.lock modules stage vendor files/test

deps:
	gem install bundler
	bundle install --binstubs
	bundle exec r10k puppetfile install --verbose --moduledir modules
	inspec vendor --overwrite
	mkdir -p files/test/inspec && mv vendor/*.tar.gz files/test/inspec/ && cd files/test/inspec && gunzip *.tar.gz && tar -xvf *.tar && rm *.tar

validate:
	bundle exec puppet parser validate manifests/*.pp
	bundle exec puppet epp validate templates/**/*.epp

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

package:
	rm -rf stage
	mkdir -p stage
	tar \
		--exclude='.git*' \
		--exclude='.tmp*' \
		--exclude='stage*' \
		--exclude='.idea*' \
		--exclude='.DS_Store*' \
		--exclude='examples' \
		--exclude='*.tar' \
		-cvf \
		stage/aem-aws-stack-provisioner-$(version).tar ./
	gzip stage/aem-aws-stack-provisioner-$(version).tar

tools:
	gem install bundler

.PHONY: ci clean deps lint package validate tools
