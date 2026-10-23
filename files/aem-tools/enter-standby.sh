#!/usr/bin/env bash
set -o nounset
set -o errexit

imds_token=$(curl --silent --fail -X PUT http://169.254.169.254/latest/api/token -H 'X-aws-ec2-metadata-token-ttl-seconds: 300')
instance_id=$(curl --silent --fail -H "X-aws-ec2-metadata-token: ${imds_token}" http://169.254.169.254/latest/meta-data/instance-id)

lifecycle_state=$(aws autoscaling describe-auto-scaling-instances --instance-ids "${instance_id}" --query AutoScalingInstances[].LifecycleState --output text)

if [ "$lifecycle_state" = "InService" ]
then

    group_name=$(aws ec2 describe-tags --filters "Name=resource-id,Values=${instance_id}" "Name=key,Values=aws:autoscaling:groupName" --output=text --query Tags[0].Value)

    aws autoscaling enter-standby --instance-ids "${instance_id}" --auto-scaling-group-name "${group_name}" --should-decrement-desired-capacity

else

    echo "Instance is in ${lifecycle_state} State. Can not Enter Standby."

fi
