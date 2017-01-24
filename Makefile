ci: clean tools deps lint

deps:
	librarian-puppet install --path modules --verbose

clean:
	rm -rf .librarian .tmp Puppetfile.lock modules

lint:
	puppet-lint \
		--fail-on-warnings \
		--no-140chars-check \
		--no-autoloader_layout-check \
		--no-documentation-check \
		--no-only_variable_string-check \
		--no-selector_inside_resource-check \
		manifests/*.pp

tools:
	gem install puppet puppet-lint librarian-puppet

.PHONY: ci clean deps lint tools
