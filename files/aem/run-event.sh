#!/usr/bin/env bash
set -o nounset
set -o errexit

event=$1

cd /opt/shinesolutions/aem-aws-stack-provisioner/
FACTER_event=${event} puppet apply --modulepath modules --hiera_config conf/hiera.yaml "manifests/${event}.pp"
