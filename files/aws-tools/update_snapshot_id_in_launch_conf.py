#!/usr/bin/env python3
#
# update_snapshot_id_in_launch_conf.py is used to update the snapshot_id in the launch configuration
#
#
#
import sys, os, logging, argparse, socket, textwrap, boto3
import base64
import string, random

__version__='0.1'
try:
  import coloredlogs
  coloredlogs.install(
    isatty = True,
    show_name = False,
    show_severity = False,
    level = logging.NOTSET,
    severity_to_style = { 'DEBUG': {'color': 'blue'}},
  )
except:
  logging.basicConfig(
    stream = sys.stdout,
    format = '%(asctime)s ' + socket.gethostname() + ' %(levelname)-8s %(message)s',
    datefmt = "%Y-%m-%d %H:%M:%S",
    level = logging.NOTSET,
  )
log = logging.getLogger(__name__)

def clamp(low, x, high):
  return low if x < low else high if x > high else x

def unwrap(txt):
  return ' '.join(textwrap.wrap(textwrap.dedent(txt).strip()))

def set_logging_level(quiet, verbose):
  level_adj = (quiet - verbose) * 10
  new_level = clamp(logging.NOTSET, logging.WARNING + level_adj, logging.CRITICAL)
  for handler in getattr(logging.getLogger(), 'handlers', []):
    handler.setLevel(new_level)
    log.debug('Set %s handler level to %d', handler.__class__.__name__, new_level)

def parse_args():
  p = argparse.ArgumentParser(
    description=unwrap("""
      Updates the Snapshot id in the Launch Configuration attached to
      the Autoscaling group for the Component and Stack-prefix
      provided.
    """),
  )
  p.add_argument(
    '--component', '-c',
    metavar = 'author-dispatcher|author-primary|author-standby|chaos-monkey|orchestrator|publish|publish-dispatcher',
    required = True,
    help     = unwrap("""
            The Component name. Required.
    """),
  )
  p.add_argument(
    '--stack-prefix', '-sp',
    metavar = 'sandpit-xxx',
    required = True,
    help     = unwrap("""
            The Stack Prefix name. Required.
        """),
  )
  p.add_argument(
    '--device', '-d',
    metavar = '/dev/xxx',
    required = True,
    help     = unwrap("""
            The device to attach the snapshot-id provided. Required.
        """),
  )
  p.add_argument(
    '--snapshot-id', '-s',
    metavar = 'snap-xxxxxxxx',
    required = True,
    help    = unwrap("""
            EBS snapshot-id to be attached to the Launch configuration. Required.
        """),
  )
  p.add_argument(
    '--verbose', '-v',
    action  = 'count',
    default = 0,
    help    = 'Be more verbose.',
  )
  p.add_argument(
    '--quiet', '-q',
    action  = 'count',
    default = 0,
    help    = 'Be less verbose.',
  )
  p.add_argument(
    '--version', '-V',
    action  = 'version',
    version = '%(prog)s {0}'.format(__version__),
    help    = 'Show version information and exit.',
  )

  args = p.parse_args()
  return args


def get_autoscaling_group(client, component, stack_prefix):
  """
    Returns AutoScalingGroup given component and stack_prefix
  """
  response = client.describe_auto_scaling_groups(MaxRecords = 100)
  for group in response['AutoScalingGroups']:
    is_stack_prefix = False
    is_component = False
    for tag in group['Tags']:
      if (tag['Key'] == 'StackPrefix' and tag['Value'] == stack_prefix):
        is_stack_prefix = True
      if (tag['Key'] == 'Component' and tag['Value'] == component):
        is_component = True
    if (is_stack_prefix and is_component):
      log.debug('Autoscaling Group: %r', group)
      return group

  while(response.get('NextToken') is not None):
    response = client.describe_auto_scaling_groups(NextToken=response.get('NextToken'), MaxRecords = 100)
    for group in response['AutoScalingGroups']:
      is_stack_prefix = False
      is_component = False
      for tag in group['Tags']:
        if (tag['Key'] == 'StackPrefix' and tag['Value'] == stack_prefix):
          is_stack_prefix = True
        if (tag['Key'] == 'Component' and tag['Value'] == component):
          is_component = True
      if (is_stack_prefix and is_component):
        log.debug('Autoscaling Group: %r', group)
        return group
  raise ValueError('No Autoscaling Group found for stack_prefix: \'{}\' and component: \'{}\'.'.format(stack_prefix, component))

def snapshot_id_exists(snapshot_id):
  """
    Checks for the existence of the snapshot
  """
  try:
    client = boto3.client('ec2')
    response = len(client.describe_snapshots(SnapshotIds=[snapshot_id])['Snapshots'])
    if response == 1:
      return True
  except:
    return False

def update_snapshot_id(launch_conf, device_name, snapshot_id):
  """
    Updates launch configuration with the device name for the snapshot id
  """
  devices = launch_conf['BlockDeviceMappings']
  for device in devices:
    if device['DeviceName'] == device_name:
      ebs = device['Ebs']
      ebs['SnapshotId'] = snapshot_id
      return
  raise ValueError('No Device found: \'{}\' in launch configuration \'{}\''.format(device_name, launch_conf['LaunchConfigurationName']))

def decode_user_data(launch_conf):
  user_data = launch_conf['UserData']
  if user_data is not None:
    launch_conf['UserData'] = base64.b64decode(user_data)

def sanitize_for_create_launch_conf(launch_conf):
  """
    Cleans up launch configuration of certain attributes
  """
  decode_user_data(launch_conf)
  launch_conf.pop('LaunchConfigurationARN')
  launch_conf.pop('CreatedTime')
  launch_conf.pop('KernelId')
  launch_conf.pop('RamdiskId')

def get_sanitized_launch_conf(client, launch_conf_name):
  launch_conf = client.describe_launch_configurations(LaunchConfigurationNames=[launch_conf_name])['LaunchConfigurations'][0]
  sanitize_for_create_launch_conf(launch_conf)
  log.debug('Launch Configuration to update: %r', launch_conf)
  return launch_conf

def delete_launch_conf(client, launch_conf_name):
  try:
    if len(client.describe_launch_configurations(LaunchConfigurationNames=[launch_conf_name])['LaunchConfigurations']) == 1:
      client.delete_launch_configuration(LaunchConfigurationName=launch_conf_name)
  except:
    log.debug('Cannot delete Launch Configuration to update: %r', launch_conf_name)

def repoint_autoscaling_group(client, group_name, launch_conf, new_launch_conf_name):
  """
    Update auto scaling group with the same launch configuration (but with a new name)
  """
  # Copy the launch configuration with the new name
  launch_conf['LaunchConfigurationName'] = new_launch_conf_name
  client.create_launch_configuration(**launch_conf)
  # Update auto scaling group with this new launch configuration
  client.update_auto_scaling_group(
    AutoScalingGroupName=group_name,
    LaunchConfigurationName=new_launch_conf_name
  )

def random_string(size=6, chars=string.ascii_uppercase + string.digits):
  return ''.join(random.choice(chars) for _ in range(size))

def update_snapshot_id_to_launch_conf(snapshot_id, component, stack_prefix, device_name):
  """
    Updates the autoscaling group's launch configuration with a new snapshot id
        1. Gets the autoscaling group  (filtered by component and stack_prefix)
        2. Copies existing launch configuration and updates the snapshot id for the given device_name
        3. Points autoscaling group to a temporary launch configuration while deleting the old launch Configuration
        4. Points autoscaling group to the new launch configuration (using original name) while deleting the temporary launch Configuration
  """
  client = boto3.client('autoscaling')
  group = get_autoscaling_group(client, component, stack_prefix)
  group_name = group['AutoScalingGroupName']
  launch_conf_name = group['LaunchConfigurationName'] # get the current name
  temp_launch_conf_name = launch_conf_name + "-" + random_string()  # create a temporary version

  if snapshot_id_exists(snapshot_id):

    try:
      # Create a sanitized launch configuration using the existing launch configuration
      launch_conf = get_sanitized_launch_conf(client, launch_conf_name)
      # Update the snapshot_id in this launch configuration
      update_snapshot_id(launch_conf, device_name, snapshot_id)

      # Update autoscaling group with this launch configuration but using the temporary name
      repoint_autoscaling_group(client, group_name, launch_conf, temp_launch_conf_name)
      # Delete the original launch configuration
      delete_launch_conf(client, launch_conf_name)
      # Update autoscaling group with this launch configuration but using the original name
      repoint_autoscaling_group(client, group_name, launch_conf, launch_conf_name)
      # Delete the temporary launch configuration
      delete_launch_conf(client, temp_launch_conf_name)
    except:
      # Delete the temporary launch configuration
      delete_launch_conf(client, temp_launch_conf_name)
  
  else:
    raise ValueError('Snapshot Id cannot be found: \'{}\''.format(snapshot_id))


def main():
  log = logging.getLogger(os.path.basename(sys.argv[0]))
  args = parse_args()
  set_logging_level(args.quiet, args.verbose)
  log.debug('Args: %r', args)
  update_snapshot_id_to_launch_conf(args.snapshot_id, args.component, args.stack_prefix, args.device)

if __name__ == '__main__':
  main()
