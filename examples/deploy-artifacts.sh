#!/usr/bin/env bash

sudo -E \
aem_host=localhost \
aem_port=4502 \
aem_debug=false \
aem_protocol=http \
aem_username=admin \
aem_password=admin \
FACTER_Descriptor=examples/descriptor.json \
FACTER_Component=author \
puppet apply \
--verbose \
--modulepath=modules/ \
--detailed-exitcodes \
manifests/deploy-artifacts.pp
