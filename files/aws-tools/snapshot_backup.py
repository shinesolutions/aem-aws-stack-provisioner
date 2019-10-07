#!/usr/bin/env python
import sys, os, logging, boto3, requests, textwrap
from botocore.config import Config
from time import sleep
from ctypes import CDLL
from socket import gethostname
from argparse import ArgumentParser
from multiprocessing import Process, Queue
from retrying import retry

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
        format = '%(asctime)s ' + gethostname() + ' %(levelname)-8s %(message)s',
        datefmt = "%Y-%m-%d %H:%M:%S",
        level = logging.NOTSET,
    )
log = logging.getLogger(__name__)

_retry_params = dict(
    stop_max_delay              = 30000,
    wait_exponential_multiplier = 150,
    wait_exponential_max        = 5000,
)
@retry(**_retry_params)
def _retry_fetch(url, parse_json):
    resp = requests.get(url)
    resp.raise_for_status()
    if parse_json:
        return resp.json()
    else:
        return resp.text

def clamp(low, x, high):
    return low if x < low else high if x > high else x

def unwrap(txt):
    return ' '.join(textwrap.wrap(textwrap.dedent(txt).strip()))

def background_sync(queue, log):
    try:
        log.info('Starting background sync loop')
        libc = CDLL('libc.so.6')
        libc.sync()
        queue.put(True)
        log.info('Completed sync call.')
        sleep(15)
        while True:
            libc.sync()
            log.info('Completed sync call.')
            sleep(15)
    except Exception as e:
        queue.put(False)
        log.error('Exception in background sync process: {0} - {1}'.format(e.__class__.__name__, str(e)))

def set_logging_level(quiet, verbose, log):
    level_adj = (quiet - verbose) * 10
    new_level = clamp(logging.NOTSET, logging.WARNING + level_adj, logging.CRITICAL)
    for handler in getattr(logging.getLogger(), 'handlers', []):
        handler.setLevel(new_level)
        log.debug('Set %s handler level to %d', handler.__class__.__name__, new_level)

def parse_args():
    p = ArgumentParser(
        description=unwrap("""
            Create a snapshot of an attached and mounted EBS volume. Calls sync
            in the background until the snapshot is started. This ensures most
            data is persisted to disk, but it isn't a guarantee. The only way
            to ensure a consistent snapshot is to unmount the volume.
        """),
    )
    p.add_argument(
        'device_or_volume',
        metavar = 'vol-xxx -OR- /dev/xxx',
        #dest    = 'device_or_volume',
        help    = unwrap("""
            The EBS volume (or the device it's attached to) that will be
            snapshotted.
        """),
    )
    p.add_argument(
        '--device-alias',
        action  = 'append',
        default = [],
        metavar = '/dev/xxx',
        help    = unwrap("""
            An alias for the device the volume is attached to. Used when
            searching for the volume. Multiple allowed.
        """),
    )

    p.add_argument(
        '--tag',
        default = [],
        action  = 'append',
        metavar = 'KEY=VALUE',
        help    = 'Add a tag to the new snapshot. Multiple allowed.'
    )
    p.add_argument(
        '--copy-tag',
        action  = 'append',
        default = [],
        metavar = 'KEY',
        help    = 'Copy a tag from the original volume to the snapshot. Multiple allowed.',
    )

    p.add_argument(
        '--snapshot-description',
        default = None,
        metavar = 'DESC',
        help    = 'The description to use when creating the snapshot.',
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
            self._id_document = self._ec2dynamic('instance-identity/document', parse_json = True)
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

    def _ec2md(self, key, parse_json = False):
        url = os.path.join(self._ec2md_service_base_url, 'meta-data', key)
        return _retry_fetch(url, parse_json)

    def _ec2dynamic(self, key, parse_json = False):
        url = os.path.join(self._ec2md_service_base_url, 'dynamic', key)
        return _retry_fetch(url, parse_json)

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
    def volumes(self, devices = []):
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
        log.debug('%r', filters)
        return list(self.resource.volumes.filter(
            Filters = filters,
        ))

def parse_snapshot_args(snapshot_args, args):
    snapshot_args = snapshot_args.copy()
    if args.snapshot_description is not None:
        snapshot_args['Description'] = str(args.snapshot_description)
    return snapshot_args

def start_sync_process(target, log):
    queue = Queue()
    sync = Process(target=target, name='background-sync', args=(queue,log))
    sync.daemon = True
    sync.start()
    if not queue.get():
        log.error('Exception in backup sync process - some writes may not have made it to disk')
        raise SystemExit(2)

def split_cli_tag(cli_tag):
    k, e, v = cli_tag.partition('=')
    if k == '' or e == '' or v == '':
        raise Exception('Unable to split tag: %s', cli_tag)
    return k, v

@retry(**_retry_params)
def start_snapshot(volume, log):
    snapshot = volume.create_snapshot(**snapshot_args)
    log.info('Started snapshot %r -- waiting for completion.', snapshot)
    return snapshot

@retry(**_retry_params)
def tag_snapshot(snapshot, snapshot_tags):
    snapshot.create_tags(Tags = [ dict(Key=k, Value=v) for k, v in snapshot_tags.iteritems() ])

if __name__ == '__main__':
    log = logging.getLogger(os.path.basename(sys.argv[0]))
    args = parse_args()
    set_logging_level(args.quiet, args.verbose, log)
    log.debug('Args: %r', args)

    boto3_config = Config(
        retries = {
            'max_attempts': 120
            }
        )

    ec2      = boto3.resource('ec2')
    instance = ec2_instance()
    if args.device_or_volume.startswith('vol-'):
        volume = args.device_or_volume
    else:
        devices     = [ args.device_or_volume ]
        if os.path.islink(args.device_or_volume):
            devices.append(os.path.realpath(args.device_or_volume))
        devices.extend(args.device_alias)
        log.debug('Full device list: %r', devices)
        volumes = instance.volumes(devices)
        log.debug('Volume list: %r', volumes)
        if len(volumes) == 0:
            log.error('No volumes found matching devices %r -- unable to continue.', devices)
            raise SystemExit(3)
        elif len(volumes) != 1:
            log.error('Found more than one volume %r -- unable to continue.', [v.id for v in volumes])
            raise SystemExit(3)
        else:
            volume = volumes.pop().id
    volume = ec2.Volume(volume)
    try:
        volume.load()
    except:
        log.error('Exception while fetching volume information.')
        raise
    log.debug('Found volume %r in availability zone %s.', volume, volume.availability_zone)
    volume_tags = dict(( (t['Key'], t['Value']) for t in volume.tags or () ))
    log.debug('Volume tags: %r.', volume_tags)

    snapshot_args = parse_snapshot_args(dict(VolumeId = volume.id), args)
    log.debug('Snapshot args: %r', snapshot_args)

    snapshot_tags = dict(( split_cli_tag(tag) for tag in args.tag))
    for tag in args.copy_tag:
        if tag not in volume_tags:
            log.warning('Cannot copy tag %s -- volume has no such tag.', tag)
        else:
            snapshot_tags[tag] = volume_tags[tag]
    log.debug('Snapshot tags: %r', snapshot_tags)

    log.debug('Running on instance %s in availability zone %s', instance.instance_id, instance.availability_zone)

    start_sync_process(background_sync, log)

    snapshot = start_snapshot(volume, log)
    tag_snapshot(snapshot, snapshot_tags)
    
    ec2.meta.client.get_waiter('snapshot_completed').wait(
        SnapshotIds=[
            snapshot.id,
        ],
        WaiterConfig={
            'Delay': 15,
            'MaxAttempts': 240
        }
    )

    log.info('Snapshot %s complete.', snapshot.id)
    print(snapshot.id)
