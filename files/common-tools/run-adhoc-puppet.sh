#!/bin/bash

set -o errexit
set -o nounset

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 adhoc_puppet_file.tar"
  exit 1
fi

if [ -d /tmp/aem-adhoc-puppet ]; then
  rm -rf /tmp/aem-adhoc-puppet
fi


data_bucket=$(/opt/puppetlabs/bin/facter data_bucket)
stack_prefix=$(/opt/puppetlabs/bin/facter stackprefix)
adhoc_puppet_file="$1"

# download the adhoc puppet tar files
mkdir -p /tmp/aem-adhoc-puppet
aws s3 cp s3://"$data_bucket"/"$stack_prefix"/"$adhoc_puppet_file" /tmp
tar xvf /tmp/"$adhoc_puppet_file" -C /tmp/aem-adhoc-puppet && rm -f /tmp/"$adhoc_puppet_file"

# translate puppet exit code to follow convention
translate_puppet_exit_code() {

  exit_code="$1"
  if [ "$exit_code" -eq 0 ] || [ "$exit_code" -eq 2 ]; then
    exit_code=0
  else
    exit "$exit_code"
  fi

  return "$exit_code"
}


# execute the main.pp within the tar
cd /tmp/adhoc_puppet_file
puppet apply \
  --detailed-exitcodes \
  --logdest /tmp/adhoc_puppet_run.log \
  --modulepath modules \
  --hiera_config hiera.yaml \
  main.pp

  translate_puppet_exit_code "$?"
