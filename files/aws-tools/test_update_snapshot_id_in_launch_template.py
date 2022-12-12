#!/usr/bin/env python3
#
# test_update_snapshot_id_in_launch_template.py is used to update the snapshot_id in the launch template
#
#
#
import os
import unittest
import boto3

from moto import mock_autoscaling, mock_ec2
from mock import patch
from update_snapshot_id_in_launch_template import update_snapshot_id_in_launch_template


class TestAwsAutoScalingGroup(unittest.TestCase):
    """
    Moto mock AwsAutoScalingGroup tests
    """

    @mock_autoscaling
    @mock_ec2
    def test_update_snapshot_id_in_launch_template(self):
        os.environ["AWS_REGION"] = "ap-southeast-2"
        asg_name = "mock-asg"
        aws_region = os.getenv("AWS_REGION")
        asg_client = boto3.client("autoscaling", region_name=aws_region)
        ec2_client = boto3.client("ec2", region_name=aws_region)
        image_response = ec2_client.describe_images()
        image_id = image_response["Images"][0]["ImageId"]
        response_clt = ec2_client.create_launch_template(
            LaunchTemplateName='mock-launch-template',
            LaunchTemplateData={
                'BlockDeviceMappings': [
                    {
                        "DeviceName": "/dev/sdb",
                        "Ebs": {
                            "VolumeSize": 100,
                        },
                    },
                    {
                        "DeviceName": "/dev/sdc",
                        "Ebs": {
                            "VolumeSize": 100,
                        },
                    },
                ],
                'ImageId': image_id,
                'InstanceType': "m5.xlarge",
                'KeyName': 'mock_key',
            },
            TagSpecifications=[
                {
                    "ResourceType": "instance",
                    "Tags": [{"Key": "Component", "Value": "publish"}, {"Key": "StackPrefix", "Value": "mock-stack"}],
                }
            ]
        )

        asg_client.create_auto_scaling_group(
            AutoScalingGroupName=asg_name,
            MinSize=3,
            MaxSize=3,
            DesiredCapacity=3,
            LaunchTemplate={
                'LaunchTemplateId': response_clt['LaunchTemplate']['LaunchTemplateId'],
                'Version':  str(response_clt['LaunchTemplate']['LatestVersionNumber'])
            },
            AvailabilityZones=[
                "%sa" % aws_region,
                "%sb" % aws_region,
                "%sc" % aws_region,
            ],
            Tags=[
                {
                    'Key': 'Component',
                    'Value': 'publish',
                    'PropagateAtLaunch': True
                },
                {
                    'Key': 'StackPrefix',
                    'Value': 'mock-stack',
                    'PropagateAtLaunch': True
                },
            ],
        )
        response_dasg = asg_client.describe_auto_scaling_groups(
            AutoScalingGroupNames=[asg_name]
        )
        instance_id = response_dasg["AutoScalingGroups"][0]["Instances"][0]["InstanceId"]
        instance_information = ec2_client.describe_instances(InstanceIds=[instance_id])
        attached_volumes = len(
            instance_information["Reservations"][0]["Instances"][0][
                "BlockDeviceMappings"
            ]
        )  # pylint: disable=C0301
        # self.assertEqual(2, attached_volumes)

        volume_id = instance_information["Reservations"][0]["Instances"][0][
            "BlockDeviceMappings"
        ][0]["Ebs"][
            "VolumeId"
        ]  # pylint: disable=C0301
        device_name = instance_information["Reservations"][0]["Instances"][0][
            "BlockDeviceMappings"
        ][0]["DeviceName"] # pylint: disable=C0301

        # Create Snapshot
        response_create_snapshot = ec2_client.create_snapshot(
            Description=" %s Snapshot" % instance_id,  # noqa
            VolumeId=volume_id,
        )
        snapshot_id = response_create_snapshot["SnapshotId"]

        with patch("update_snapshot_id_in_launch_template.update_launch_template_default_version") as update_launch_template_default_version:

            # Mock Route53 create_update_record response
            update_launch_template_default_version.return_value = {
                'LaunchTemplate': {
                    'LaunchTemplateId': 'string',
                    'LaunchTemplateName': 'string',
                    'DefaultVersionNumber': 123,
                    'LatestVersionNumber': 123,
                }
            }
            update_snapshot_id_in_launch_template(
                snapshot_id, 'publish', 'mock-stack', device_name
            )

        response_dasg_2 = asg_client.describe_auto_scaling_groups(
            AutoScalingGroupNames=[asg_name]
        )
        asg_version = response_dasg_2["AutoScalingGroups"][0]["LaunchTemplate"]["Version"]

        self.assertEqual('2', asg_version)
