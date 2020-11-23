#!/usr/bin/env python3
#
# update_hiera.py is used to updates parameters in the hiera YAML file.
#
# Exit codes:
# 2 - general error
# 3 - Can't add parameter. Parameter already exist.
# 4 - Can't change parameter. Parameter not found in hiera file.
#
#
import sys, os, logging, argparse, requests, socket, textwrap, yaml

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
            Update existing YAML parameters in a Puppet hiera file.
        """),
    )
    p.add_argument(
        '--file', '-f',
        metavar = '/etc/puppetlabs/puppet/hiera.yaml',
        required = True,
        help     = unwrap("""
            Path to the hiera file to update.
        """),
    )
    p.add_argument(
        '--dest-file', '-df',
        metavar = '/tmp/hiera.yaml',
        required = True,
        help     = unwrap("""
            Path to save the file to.
        """),
    )
    p.add_argument(
        '--parameter', '-p',
        metavar  = 'HIERA::PARAMETER',
        required = True,
        help    = unwrap("""
            The parameter which should be changed in the hiera file.
        """),
    )
    p.add_argument(
        '--parameter-value', '-pv',
        default = None,
        metavar = 'True',
        help    = unwrap("""
            Parameter value only applicable for state add and update.
        """),
    )
    p.add_argument(
        '--action', '-a',
        default = None,
        required = True,
        choices = [ 'add', 'change', 'remove' ],
        metavar = 'add, change, remove',
        help    = unwrap("""
            Action to trigger.
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

class update_hiera(object):
    def __init__(self, args):

        self.hiera_file = args.file
        self.dest_file = args.dest_file
        self.parameter = args.parameter
        log.debug('hiera_file: %r', self.hiera_file)
        log.debug('dest_file: %r', self.dest_file)
        log.debug('parameter: %r', self.parameter)

        if args.action in ('add', 'change'):
            if args.parameter_value is not None:
                if args.parameter_value.lower() in ('true'):
                    self.parameter_value = True
                elif args.parameter_value.lower() in ('false'):
                    self.parameter_value = False
                else:
                    self.parameter_value = args.parameter_value
                log.debug('parameter_value: %r', self.parameter_value)
            else:
                log.error("Error:  No parameter value defined")
                raise SystemExit(2)

    def add(self):
        hiera_file_content = self.read_hiera_file_content()
        log.debug('hiera_file_content: %r', hiera_file_content)

        if self.parameter not in hiera_file_content:
            hiera_file_content[self.parameter] = self.parameter_value
            log.debug('add parameter')
            log.debug('hiera_parameter: %r', self.parameter)
            log.debug('value: %r', hiera_file_content[self.parameter])

            self.write_hiera_file_content(content=hiera_file_content)

        else:
            log.error("Error: Can't add parameter. Parameter " + self.parameter + " already exist.")
            raise SystemExit(3)

    def change(self):
        hiera_file_content = self.read_hiera_file_content()
        log.debug('hiera_file_content: %r', hiera_file_content)

        if self.parameter in hiera_file_content:
            log.debug('change parameter')
            log.debug('hiera_parameter: %r', self.parameter)
            log.debug('old value: %r', hiera_file_content[self.parameter])
            log.debug('new value: %r', self.parameter_value)

            hiera_file_content[self.parameter] = self.parameter_value
            log.debug('new value: %r', hiera_file_content[self.parameter])

            self.write_hiera_file_content(content=hiera_file_content)

        else:
            log.error("Error: Can't change parameter. Parameter " + self.parameter + " not found in hiera file.")
            raise SystemExit(4)

    def remove(self):
        hiera_file_content = self.read_hiera_file_content()
        log.debug('hiera_file_content: %r', hiera_file_content)

        if self.parameter in hiera_file_content:
            log.debug('remove parameter')
            log.debug('hiera_parameter: %r', self.parameter)
            log.debug('value: %r', hiera_file_content[self.parameter])

            del hiera_file_content[self.parameter]

            self.write_hiera_file_content(content=hiera_file_content)

        else:
            log.error("Error: Can't change parameter. Parameter " + self.parameter + " not found in hiera file.")
            raise SystemExit(4)

    def read_hiera_file_content(self, file=None):
        if file is None:
            file = self.hiera_file
        try:
            with open(file, 'r') as yamlfile:
                content = yaml.load(yamlfile)
            return content
        except Exception as e:
            log.error("Error: Can't open file:  " + file + " - " + str(e))
            raise SystemExit(2)

    def write_hiera_file_content(self, content, dest_file=None):
        if dest_file is None:
            dest_file = self.dest_file
        try:
            with open(dest_file, 'w') as yamlfile:
                yaml.dump(content, yamlfile, default_flow_style=False)
        except Exception as e:
            log.error("Error: Can't write to file: " + dest_file + " - " + str(e))
            raise SystemExit(2)

        return True

if __name__ == '__main__':
    log = logging.getLogger(os.path.basename(sys.argv[0]))
    args = parse_args()
    set_logging_level(args.quiet, args.verbose)
    log.debug('Args: %r', args)

    action = args.action
    log.debug('Action: %r', action)

    update_hiera = update_hiera(args)

    if action == 'add':
        update_hiera.add()
    elif action == 'change':
        update_hiera.change()
    elif action == 'remove':
        update_hiera.remove()
