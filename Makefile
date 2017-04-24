version ?= 0.9.0

ci: clean package

clean:
	rm -rf .librarian .tmp Puppetfile.lock modules stage

Puppetfile.lock: Puppetfile tools
	librarian-puppet install --path modules --verbose

lint: tools
	puppet-lint \
		--fail-on-warnings \
		--no-140chars-check \
		--no-autoloader_layout-check \
		--no-documentation-check \
		--no-parameter_documentation-check \
		--no-only_variable_string-check \
		--no-selector_inside_resource-check \
		--no-variable_scope-check \
		--no-top_scope_facts-check \
		--no-relative_classname_inclusion-check \
		--no-legacy_facts-check \
		--log-format "%{path} (%{check}) L%{line} %{message}" \
		manifests/*.pp
	shellcheck files/*/*.sh

package: Puppetfile.lock lint
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
