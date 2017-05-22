version ?= 1.0.0

ci: clean tools lint deps package

deps:
	librarian-puppet install --path modules --verbose

clean:
	rm -rf .librarian .tmp Puppetfile.lock modules stage

lint:
	puppet-lint \
		--fail-on-warnings \
		--no-140chars-check \
		--no-autoloader_layout-check \
		--no-documentation-check \
		--no-only_variable_string-check \
		--no-selector_inside_resource-check \
		--no-variable_scope-check \
		manifests/*.pp
	shellcheck files/*/*.sh

package:
	rm -rf stage
	mkdir -p stage
	tar \
		--exclude='.git*' \
		--exclude='.librarian*' \
		--exclude='.tmp*' \
		--exclude='stage*' \
		--exclude='.idea*' \
		--exclude='.DS_Store*' \
		-cvf \
		stage/aem-aws-stack-provisioner-$(version).tar ./
	gzip stage/aem-aws-stack-provisioner-$(version).tar

tools:
	gem install puppet puppet-lint librarian-puppet

.PHONY: ci clean deps lint package tools
