#! /bin/sh
# Set AWS resource values as Facter facts. These facts will be used in subsequent
# provisioning Puppet manifests.

data_bucket_name=$1
stack_prefix=$2

# Set EC2 instance tags as Facter facts.
# These facts are cached in /opt/puppetlabs/facter/facts.d/ on cloud-init,
# and will only be updated on recovery events.
# These facts are purposely not set on every Facter call in order to avoid
# hitting the AWS API rate limit.
instance_id=$(curl --silent http://169.254.169.254/latest/meta-data/instance-id)
# shellcheck disable=2039
aws ec2 describe-tags --filters "Name=resource-id,Values=${instance_id}" --query 'Tags[*].[Key,Value]' --output text | awk -F $'\t' '{print $1"="$2}' | grep -v -E '^(Name)=' > /opt/puppetlabs/facter/facts.d/ec2-tags.txt

# Set S3 bucket name as Facter fact.
if [ ! -z "${data_bucket_name}" ]; then
  echo "data_bucket=${data_bucket_name}" > /opt/puppetlabs/facter/facts.d/s3-buckets.txt
fi

# Set stack Facter facts.
aws s3 cp "s3://${data_bucket_name}/${stack_prefix}/stack-facts.txt" /opt/puppetlabs/facter/facts.d/stack-facts.txt
