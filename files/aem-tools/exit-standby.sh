#!/usr/bin/env bash
set -o nounset
set -o errexit

instance_id=$(curl --silent http://169.254.169.254/latest/meta-data/instance-id)
group_name=$(aws ec2 describe-tags --filters "Name=resource-id,Values=${instance_id}" "Name=key,Values=aws:autoscaling:groupName" --output=text --query Tags[0].Value)

aws autoscaling exit-standby --instance-ids "${instance_id}" --auto-scaling-group-name "${group_name}"
