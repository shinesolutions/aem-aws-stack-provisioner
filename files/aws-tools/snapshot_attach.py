#!/usr/bin/env python
import sys, os, logging, argparse, jmespath, boto3, requests, json, logging, socket, sh, textwrap
from retrying import retry
from itertools import imap, repeat
from collections import namedtuple

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

fs_line = namedtuple(
    'fs_line',
    (
        'spec',
        'file',
        'vfstype',
        'mntops',
        'freq',
        'passno',
    ),
)

_retry_params = dict(
    stop_max_delay              = 30000,
    wait_exponential_multiplier = 150,
    wait_exponential_max        = 5000,
)
@retry(**_retry_params)
def _retry_fetch(url, json):
    resp = requests.get(url)
    resp.raise_for_status()
    if json:
        return resp.json()
    else:
        return resp.text

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
            Replace an attached (and possibly mounted) EBS volume with a new
            EBS volume (possibly created from a snapshot).
        """),
        epilog=unwrap("""
            ** By default, this property is set based on the snapshot used to
            create the volume.
        """),
    )
    p.add_argument(
        '--device', '-d',
        metavar = '/dev/xxx',
        required = True,
        help     = unwrap("""
            The device to attach the EBS volume to. If a volume is already
            attached to this device it is detached first. Required.
        """),
    )
    p.add_argument(
        '--device-alias', '-a',
        action  = 'append',
        default = [],
        metavar = '/dev/xxx',
        help    = unwrap("""
            An alias for the device -- also checked when unmounting and
            detaching. Multiple allowed.
        """),
    )
    p.add_argument(
        '--mount-point', '-m',
        default = None,
        metavar = 'PATH',
        help    = unwrap("""
            'Mount point for new volume after it\'s attached. If not provided,
            will just call \'mount -a\'.
        """),
    )
    p.add_argument(
        '--no-delete-on-termination',
        action = 'store_true',
        help   = 'Don\'t enable DeleteOnTermination for this volume',
    )

    p.add_argument(
        '--snapshot-id', '-s',
        default = None,
        metavar = 'snap-xxxxxxxx',
        help    = unwrap("""
            EBS snapshot ID to create the new volume from. If not specified, a
            raw volume will be created.
        """),
    )

    p.add_argument(
        '--volume-size',
        default = None,
        metavar = 'INT',
        help    = unwrap("""
            The size of EBS volume to create (in GB). Required if no
            '--snapshot-id' is provided. **
        """),
    )
    p.add_argument(
        '--volume-type',
        default = None,
        metavar = 'TYPE',
        help    = unwrap("""
            The type of EBS volume to create. If not set, the EC2 default is
            currently \'standard\'.
        """),
    )
    p.add_argument(
        '--volume-iops',
        default = None,
        metavar = 'INT',
        help    = unwrap("""
            The number of (IOPS) to provision for the volume. Only valid for
            Provisioned IOPS SSD volumes.
        """),
    )
    p.add_argument(
        '--volume-encrypted',
        action  = 'store_true',
        default = None,
        help    = 'Enable encryption on the created volume. **',
    )
    p.add_argument(
        '--volume-kms-key-id',
        default = None,
        metavar = 'ARN',
        help    = unwrap("""
            The full ARN of the KMS customer master key to use when creating
            the encrypted volume.
        """),
    )

    p.add_argument(
        '--volume-tag', '-t',
        default = [],
        action  = 'append',
        metavar = 'KEY=VALUE',
        help    = 'Add a tag to the new volume.'
    )
    p.add_argument(
        '--copy-volume-tag',
        action  = 'append',
        default = [],
        metavar = 'KEY',
        help    = 'Copy a tag from the original volume. Multiple allowed.',
    )
    p.add_argument(
        '--copy-snapshot-tag',
        action  = 'append',
        default = [],
        metavar = 'KEY',
        help    = 'Copy a tag from the source snapshot. Multiple allowed.',
    )

    p.add_argument(
        '--fs-type',
        default = None,
        metavar = 'TYPE',
        help    = unwrap("""
            Filesystem type to format volume with. Required (and only used) if
            no snapshot ID is provided.
        """),
    )
    p.add_argument(
        '--fs-options',
        default = "",
        metavar = 'OPTIONS',
        help    = unwrap("""
            Filesystem options to pass to 'mkfs'. Only used if no snapshot ID
            is provided.
        """),
    )

    p.add_argument(
        '--sudo', '-S',
        action  = 'store_true',
        default = False,
        help    = unwrap("""
            'Use sudo when calling mount/unmount/mkfs. Will *not* prompt for a
            password.
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

class ec2_metadata(object):
    _ec2md_service_base_url = 'http://169.254.169.254/latest/'
    @property
    def id_document(self):
        if getattr(self, '_id_document', None) is None:
            self._id_document = self._ec2dynamic('instance-identity/document', json = True)
        return self._id_document

    @property
    def instance_id(self):
        return self.id_document.get('instanceId')

    @property
    def availability_zone(self):
        return self.id_document.get('availabilityZone')

    @property
    def region(self):
        return self.id_document.get('region')

    def _ec2md(self, key, json = False):
        url = os.path.join(self._ec2md_service_base_url, 'meta-data', key)
        return _retry_fetch(url, json)

    def _ec2dynamic(self, key, json = False):
        url = os.path.join(self._ec2md_service_base_url, 'dynamic', key)
        return _retry_fetch(url, json)


class ec2_instance(object):
    def __init__(self):
        self.md = ec2_metadata()
        self.resource = boto3.resource('ec2', region_name = self.region).Instance(self.instance_id)

    @property
    def region(self):
        return self.md.region

    @property
    def availability_zone(self):
        return self.md.availability_zone

    @property
    def instance_id(self):
        return self.md.instance_id

    @retry(**_retry_params)
    def unmount(self, devices, sudo = False):
        log.debug('unmount(%r, %r)', devices, sudo)
        mounted = filter(lambda mount: mount.spec in devices, self._mounts)
        if mounted:
            if len(mounted) > 1:
                for m in mounted:
                    log.critical(str(m))
                raise Exception('Found more than one mount for device "%s"', devices[0])
            mount = mounted.pop()
            log.info('Unmounting %s mounted at %s', mount.spec, mount.file)
            if sudo:
                sh.sudo('-n', 'umount', mount.spec)
            else:
                sh.umount(mount.spec)
            self._orig_mount = mount
            return mount
        log.info('Device %s not found in mounted filesystems', devices[0])
        return

    @retry(**_retry_params)
    def detach(self, devices):
        waiter = self.resource.meta.client.get_waiter('volume_available')
        current_volumes = list(self._volumes(devices))
        if current_volumes:
            if len(current_volumes) > 1:
                for v in current_volumes:
                    log.critical(str(v))
                raise Exception('Found more than one volume attached to device "%s"', devices[0])
            current_volume = current_volumes.pop()
            log.info('Detaching current volume: %s', current_volume)
            current_volume.detach_from_instance(instance.instance_id)
            log.info('Waiting for current volume to reach state "available"')
            waiter.wait( VolumeIds=(current_volume.id,) )
            self._orig_volume = current_volume
            return current_volume
        log.info('Device %s not found in list of attached EBS volumes', devices[0])
        return

    @retry(**_retry_params)
    def attach(self, volume, device, no_delete_on_termination):
        waiter = self.resource.meta.client.get_waiter('volume_in_use')
        log.info('Attaching volume %s to instance %s', volume.id, self.instance_id)
        self.resource.attach_volume(
            VolumeId = volume.id,
            Device   = device,
        )
        log.info('Waiting for volume %s to reach state \'in_use\'', volume.id)
        waiter.wait( VolumeIds=(volume.id,) )
        if not no_delete_on_termination:
            log.info('Setting DeleteOnTermination=True for volume %s', volume.id)
            self.resource.modify_attribute(
                Attribute = 'blockDeviceMapping',
                BlockDeviceMappings = [{
                    'DeviceName': device,
                    'Ebs': {
                        'VolumeId': volume.id,
                        'DeleteOnTermination': True,
                    },
                }],
            )

    def format(device, fs_type, fs_options, sudo = False):
        mkfs_args = ['--type=%s'%fs_type]
        if fs_options:
            mkfs_args.extend(fs_options.split())
        if sudo:
            mkfs = sh.sudo('-n', 'mkfs', *mkfs_args)
        else:
            mkfs = sh.mkfs(*mkfs_args)
        return mkfs

    @retry(**_retry_params)
    def mount(self, device = None, mount_point = None, sudo = False):
        if device is None or mount_point is None:
            log.debug('Mounting all filesystems')
            mount_args = ['-a']
        else:
            log.debug('Mounting %s', mount_point)
            mount_args = [device, mount_point]
        if sudo:
            mount = sh.sudo('-n', 'mount', *mount_args)
        else:
            mount = sh.mount(*mount_args)
        return mount

    @retry(**_retry_params)
    def _volumes(self, devices = []):
        filters = [
            {
                'Name': 'attachment.instance-id',
                'Values': ( str(self.instance_id), ),
            },
        ]
        if devices:
            filters.extend([
                {
                    'Name': 'attachment.device',
                    'Values': devices,
                },
            ])
        log.debug(json.dumps(filters))
        return self.resource.volumes.filter(
            Filters = filters,
        )

    @property
    def _mounts(self, mounts_path = '/proc/mounts'):
        return imap(lambda line: fs_line(*(line.strip().split())), open(mounts_path, 'r'))

def parse_volume_args(volume_args, args):
    volume_args = volume_args.copy()
    if args.volume_size is not None:
        volume_args['Size'] = int(args.volume_size)
    if args.volume_type is not None:
        volume_args['VolumeType'] = str(args.volume_type)
        if args.volume_type == 'io1':
            if args.volume_iops is None:
                raise Exception("'--volume-iops' is required when '--volume-type' is 'io1'")
            volume_args['Iops'] = int(args.volume_iops)
    if args.volume_encrypted is not None:
        volume_args['Encrypted'] = bool(args.volume_encrypted)
    if args.volume_kms_key_id is not None:
        volume_args['KmsKeyId'] = str(args.volume_kms_key_id)
    return volume_args



if __name__ == '__main__':
    log = logging.getLogger(os.path.basename(sys.argv[0]))
    args = parse_args()
    set_logging_level(args.quiet, args.verbose)
    log.debug('Args: %r', args)

    ec2         = boto3.resource('ec2')
    instance    = ec2_instance()
    devices     = [ args.device ]
    volume_args = parse_volume_args({}, args)
    volume_tags = {}

    log.debug('Running on instance %s in availability zone %s', instance.instance_id, instance.availability_zone)

    if os.path.islink(args.device):
        devices.append(os.path.realpath(args.device))
    devices.extend(args.device_alias)
    log.debug('Full device list: %r', devices)

    volume_args['AvailabilityZone'] = instance.availability_zone
    needs_format = False
    if args.snapshot_id:
        snapshot = ec2.Snapshot(args.snapshot_id)
        snapshot.wait_until_completed()
        log.debug('Using snapshot %r', snapshot)
        volume_args['SnapshotId'] = snapshot.id
        snapshot_tags = dict(( (t['Key'], t['Value']) for t in snapshot.tags or () ))
        log.debug('Snapshot tags: %r', snapshot_tags)
        for key in args.copy_snapshot_tag:
            volume_tags[key] = snapshot_tags[key]
    else:
        log.info('No snapshot set -- will create a blank volume')
        if args.volume_size is None:
            raise Exception("'--volume-size' is required when '--snapshot-id' is not provided")
        if args.fs_type is None:
            raise Exception("'--fs-type' is required when '--snapshot-id' is not provided")
        needs_format = True

    unmount     = instance.unmount(devices, args.sudo)
    orig_volume = instance.detach(devices)

    orig_volume_tags = dict(( (t['Key'], t['Value']) for t in orig_volume.tags or () ))
    log.debug('Original volume tags: %r', orig_volume_tags)
    for key in args.copy_volume_tag:
        volume_tags[key] = orig_volume_tags[key]

    for tag in args.volume_tag:
        key, _, value = tag.partition('=')
        volume_tags[key] = value

    new_volume  = ec2.create_volume(**volume_args)
    log.info('Volume %r created.', new_volume)
    ec2.meta.client.get_waiter('volume_available').wait( VolumeIds = (new_volume.id,) )
    if volume_tags:
        new_volume.create_tags(Tags = [ dict(Key=k, Value=v) for k, v in volume_tags.iteritems() ])

    attach = instance.attach(new_volume, args.device, args.no_delete_on_termination)
    if needs_format:
        instance.format(device, args.fs_type, args.fs_options, args.sudo)
    mount  = instance.mount(args.device, args.mount_point, args.sudo)

    log.info('Deleting original volume: %s', orig_volume)
    orig_volume.delete()
