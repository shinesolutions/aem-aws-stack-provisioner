#!/usr/bin/env python3
#
# update_snapshot_id_in_launch_template.py is used to update the snapshot_id in the launch template
#
#
#
import argparse
import logging
import os
import textwrap
import socket
import sys
import boto3

__version__ = "0.1"
try:
    import coloredlogs

    coloredlogs.install(
        isatty=True,
        show_name=False,
        show_severity=False,
        level=logging.NOTSET,
        severity_to_style={"DEBUG": {"color": "blue"}},
    )
except:
    logging.basicConfig(
        stream=sys.stdout,
        format="%(asctime)s " + socket.gethostname() + " %(levelname)-8s %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        level=logging.NOTSET,
    )
log = logging.getLogger(__name__)


def clamp(low, x, high):
    return low if x < low else high if x > high else x


def unwrap(txt):
    return " ".join(textwrap.wrap(textwrap.dedent(txt).strip()))


def set_logging_level(quiet, verbose):
    level_adj = (quiet - verbose) * 10
    new_level = clamp(logging.NOTSET, logging.WARNING + level_adj, logging.CRITICAL)
    for handler in getattr(logging.getLogger(), "handlers", []):
        handler.setLevel(new_level)
        log.debug("Set %s handler level to %d", handler.__class__.__name__, new_level)


def parse_args():
    p = argparse.ArgumentParser(
        description=unwrap(
            """
      Updates the Snapshot id in the Launch Template assigned to
      the Autoscaling group for the Component and Stack-prefix
      provided.
    """
        ),
    )
    p.add_argument(
        "--component",
        "-c",
        metavar="author-dispatcher|author-primary|author-standby|chaos-monkey|orchestrator|publish|publish-dispatcher",
        required=True,
        help=unwrap(
            """
            The Component name. Required.
    """
        ),
    )
    p.add_argument(
        "--stack-prefix",
        "-sp",
        metavar="sandpit-xxx",
        required=True,
        help=unwrap(
            """
            The Stack Prefix name. Required.
        """
        ),
    )
    p.add_argument(
        "--device",
        "-d",
        metavar="/dev/xxx",
        required=True,
        help=unwrap(
            """
            The device to attach the snapshot-id provided. Required.
        """
        ),
    )
    p.add_argument(
        "--snapshot-id",
        "-s",
        metavar="snap-xxxxxxxx",
        required=True,
        help=unwrap(
            """
            EBS snapshot-id to be attached to the Launch template. Required.
        """
        ),
    )
    p.add_argument(
        "--verbose",
        "-v",
        action="count",
        default=0,
        help="Be more verbose.",
    )
    p.add_argument(
        "--quiet",
        "-q",
        action="count",
        default=0,
        help="Be less verbose.",
    )
    p.add_argument(
        "--version",
        "-V",
        action="version",
        version="%(prog)s {0}".format(__version__),
        help="Show version information and exit.",
    )

    args = p.parse_args()
    return args


def get_autoscaling_group(component, stack_prefix):
    """
    Returns AutoScalingGroup given component and stack_prefix
    """
    client = boto3.client("autoscaling")
    response = client.describe_auto_scaling_groups(MaxRecords=100)
    for group in response["AutoScalingGroups"]:
        is_stack_prefix = False
        is_component = False
        for tag in group["Tags"]:
            if tag["Key"] == "StackPrefix" and tag["Value"] == stack_prefix:
                is_stack_prefix = True
            if tag["Key"] == "Component" and tag["Value"] == component:
                is_component = True
        if is_stack_prefix and is_component:
            log.debug("Autoscaling Group: %r", group)
            return group

    while response.get("NextToken") is not None:
        response = client.describe_auto_scaling_groups(
            NextToken=response.get("NextToken"), MaxRecords=100
        )
        for group in response["AutoScalingGroups"]:
            is_stack_prefix = False
            is_component = False
            for tag in group["Tags"]:
                if tag["Key"] == "StackPrefix" and tag["Value"] == stack_prefix:
                    is_stack_prefix = True
                if tag["Key"] == "Component" and tag["Value"] == component:
                    is_component = True
            if is_stack_prefix and is_component:
                log.debug("Autoscaling Group: %r", group)
                return group
    raise ValueError(
        "No Autoscaling Group found for stack_prefix: '{}' and component: '{}'.".format(
            stack_prefix, component
        )
    )


def snapshot_id_exists(snapshot_id):
    """
    Checks for the existence of the snapshot
    """
    try:
        client = boto3.client("ec2")
        response = len(
            client.describe_snapshots(SnapshotIds=[snapshot_id])["Snapshots"]
        )
        if response == 1:
            return True
    except:
        return False


def create_new_launch_template_version(
    launch_tmpl_id, launch_tmpl_version, device_name, snapshot_id
):
    """
    Create a new launch template version based on the previous version &
    """
    client = boto3.client("ec2")
    response = client.create_launch_template_version(
        LaunchTemplateData={
            "BlockDeviceMappings": [
                {
                    "DeviceName": device_name,
                    "Ebs": {
                        "SnapshotId": snapshot_id,
                    },
                },
            ],
        },
        LaunchTemplateId=launch_tmpl_id,
        SourceVersion=launch_tmpl_version,
        VersionDescription=f"Snapshot ID {snapshot_id}",
    )

    return response["LaunchTemplateVersion"]


def update_launch_template_default_version(launch_tmpl_id, new_default_version):
    """
    Updates the default version of the Launch template
    """
    client = boto3.client("ec2")
    client.modify_launch_template(
        LaunchTemplateId=launch_tmpl_id, DefaultVersion=str(new_default_version)
    )


def repoint_autoscaling_group(asg_name, launch_template_id, launch_template_version):
    """
    Update auto scaling group with the new version of the launch template
    """
    client = boto3.client("autoscaling")
    # Update auto scaling group with new launch template version
    client.update_auto_scaling_group(
        AutoScalingGroupName=asg_name,
        LaunchTemplate={
            "LaunchTemplateId": launch_template_id,
            "Version": str(launch_template_version),
        },
    )


def update_snapshot_id_in_launch_template(
    snapshot_id, component, stack_prefix, device_name
):
    """
    Updates the autoscaling group's launch template with a new snapshot id
        1. Gets the autoscaling group  (filtered by component and stack_prefix)
        2. Creates a new Launch template version based on
           the existing Launch Template with updated snapshot id
        3. Update the Launch template default version
        4. Points autoscaling group to the new launch template version
    """
    log.info("Get %s AutoScalingGroup information.", component)
    asg = get_autoscaling_group(component, stack_prefix)
    log.info("Successfully retrieved %s AutoScalingGroup information.", component)

    asg_name = asg["AutoScalingGroupName"]
    launch_tmpl_id = asg["LaunchTemplate"]["LaunchTemplateId"]
    launch_tmpl_version = asg["LaunchTemplate"]["Version"]

    log.info("Validate if snapshot id %s exist.", snapshot_id)
    if snapshot_id_exists(snapshot_id):
        log.info("Successfully validated that snapshot id %s exist.", snapshot_id)

        try:
            log.info(
                "Create new Launch Template version with snapshot id %s.",
                snapshot_id
            )
            response_new_launch_template_version = create_new_launch_template_version(
                launch_tmpl_id, launch_tmpl_version, device_name, snapshot_id
            )
            log.info(
                "Successfully created new Launch Template version with snapshot id %s.",
                snapshot_id
            )

            # Update Launch Template default version to new version
            new_launch_template_id = response_new_launch_template_version[
                "LaunchTemplateId"
            ]
            new_launch_template_version = response_new_launch_template_version[
                "VersionNumber"
            ]
            new_launch_template_default_version = response_new_launch_template_version[
                "DefaultVersion"
            ]
            log.info("New Launch Template version %s.", new_launch_template_version)
            if not new_launch_template_default_version:
                log.info(
                    "Update Launch Template %s default version from %s to %s.",
                    launch_tmpl_id,
                    launch_tmpl_version,
                    new_launch_template_version

                )
                update_launch_template_default_version(
                    launch_tmpl_id, new_launch_template_version
                )
                log.info(
                    "Successfully updated Launch Template %s default version to %s.",
                    launch_tmpl_id,
                    new_launch_template_version
                )

            log.info(
                "Update AutoScalingGroup Launch Template version from %s to %s.",
                launch_tmpl_version,
                new_launch_template_version
            )
            repoint_autoscaling_group(
                asg_name, new_launch_template_id, new_launch_template_version
            )
            log.info(
                "Successfully updated AutoScalingGroup Launch Template version from %s to %s.",
                launch_tmpl_version,
                new_launch_template_version

            )
        except Exception as error:
            raise error

    else:
        raise ValueError("Snapshot Id cannot be found: '{}'".format(snapshot_id))


def main():
    log = logging.getLogger(os.path.basename(sys.argv[0]))
    args = parse_args()
    set_logging_level(args.quiet, args.verbose)
    log.debug("Args: %r", args)
    update_snapshot_id_in_launch_template(
        args.snapshot_id, args.component, args.stack_prefix, args.device
    )


if __name__ == "__main__":
    main()
