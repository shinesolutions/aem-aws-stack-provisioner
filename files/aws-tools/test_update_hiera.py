#!/usr/bin/env python3
"""
Tests for update_hiera.py, run as schedule-snapshots.sh runs it on the instances:
as a script on a copy of local.yaml, checking the written file and the exit code.
"""
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

import yaml

UPDATE_HIERA = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'update_hiera.py')

PARAMETER = 'aem_orchestrator::scheduled_jobs::enable::offline_snapshot'

# Hiera data as in data/orchestrator.yaml and data/common.yaml, with a scheduled job flag
# that schedule-snapshots.sh changes (the backslash joins the long alias line)
LOCAL_YAML = """---
orchestrator::aem_orchestrator_version: 5.0.0
orchestrator::base_dir: "%{lookup('common::base_dir')}"
action_scheduled_jobs::offline_snapshot_enable: \
"%{alias('aem_orchestrator::scheduled_jobs::enable::offline_snapshot')}"
aem_orchestrator::scheduled_jobs::enable::offline_snapshot: false
"""


class TestUpdateHiera(unittest.TestCase):
    """
    update_hiera.py add, change and remove actions, values and exit codes
    """

    def setUp(self):
        self.tmp_dir = tempfile.mkdtemp()
        self.hiera_file = os.path.join(self.tmp_dir, 'local.yaml')
        self.dest_file = os.path.join(self.tmp_dir, 'dest-local.yaml')
        with open(self.hiera_file, 'w', encoding='utf-8') as hiera_file:
            hiera_file.write(LOCAL_YAML)

    def tearDown(self):
        shutil.rmtree(self.tmp_dir)

    def update_hiera(self, action, parameter, value=None, hiera_file=None):
        """
        Runs update_hiera.py and returns its exit code
        """
        command = [
            sys.executable, UPDATE_HIERA,
            '--file', hiera_file or self.hiera_file,
            '--dest-file', self.dest_file,
            '--action', action,
            '--parameter', parameter,
        ]
        if value is not None:
            command.extend(['--parameter-value', value])
        return subprocess.run(command, capture_output=True, check=False).returncode

    def read(self, path):
        """
        Returns the parsed content of a YAML file
        """
        with open(path, encoding='utf-8') as yaml_file:
            return yaml.safe_load(yaml_file)

    def test_change_parameter_to_true(self):
        """change sets True as the boolean true and keeps the other values"""
        self.assertEqual(0, self.update_hiera('change', PARAMETER, 'True'))
        content = self.read(self.dest_file)
        self.assertIs(True, content[PARAMETER])
        self.assertEqual('5.0.0', content['orchestrator::aem_orchestrator_version'])

    def test_change_parameter_to_false(self):
        """change sets False as the boolean false"""
        self.assertEqual(0, self.update_hiera('change', PARAMETER, 'True'))
        self.hiera_file = self.dest_file
        self.assertEqual(0, self.update_hiera('change', PARAMETER, 'False'))
        self.assertIs(False, self.read(self.dest_file)[PARAMETER])

    def test_boolean_values_ignore_case(self):
        """true and false are booleans in any case"""
        self.assertEqual(0, self.update_hiera('change', PARAMETER, 'TRUE'))
        self.assertIs(True, self.read(self.dest_file)[PARAMETER])
        self.assertEqual(0, self.update_hiera('change', PARAMETER, 'false'))
        self.assertIs(False, self.read(self.dest_file)[PARAMETER])

    def test_other_values_stay_strings(self):
        """Values that are only part of true or false, or other words, stay strings"""
        for value in ('t', 'rue', 'fal', 'yes', 'enable'):
            self.assertEqual(0, self.update_hiera('change', PARAMETER, value))
            self.assertEqual(value, self.read(self.dest_file)[PARAMETER])

    def test_interpolation_strings_survive(self):
        """lookup() and alias() interpolation strings are written back unchanged"""
        self.assertEqual(0, self.update_hiera('change', PARAMETER, 'True'))
        content = self.read(self.dest_file)
        self.assertEqual("%{lookup('common::base_dir')}", content['orchestrator::base_dir'])
        self.assertEqual(
            "%{alias('aem_orchestrator::scheduled_jobs::enable::offline_snapshot')}",
            content['action_scheduled_jobs::offline_snapshot_enable'],
        )

    def test_change_missing_parameter_exits_4(self):
        """change of a parameter that isn't in the file exits with 4 and writes nothing"""
        parameter = 'aem_orchestrator::scheduled_jobs::enable::live_snapshot'
        self.assertEqual(4, self.update_hiera('change', parameter, 'True'))
        self.assertFalse(os.path.exists(self.dest_file))

    def test_add_parameter(self):
        """add of a new parameter keeps the existing ones"""
        parameter = 'aem_orchestrator::scheduled_jobs::enable::live_snapshot'
        self.assertEqual(0, self.update_hiera('add', parameter, 'True'))
        content = self.read(self.dest_file)
        self.assertIs(True, content[parameter])
        self.assertIs(False, content[PARAMETER])

    def test_add_existing_parameter_exits_3(self):
        """add of a parameter that is already in the file exits with 3"""
        self.assertEqual(3, self.update_hiera('add', PARAMETER, 'True'))
        self.assertFalse(os.path.exists(self.dest_file))

    def test_remove_parameter(self):
        """remove deletes only the parameter"""
        self.assertEqual(0, self.update_hiera('remove', PARAMETER))
        content = self.read(self.dest_file)
        self.assertNotIn(PARAMETER, content)
        self.assertEqual("%{lookup('common::base_dir')}", content['orchestrator::base_dir'])

    def test_remove_missing_parameter_exits_4(self):
        """remove of a parameter that isn't in the file exits with 4"""
        self.assertEqual(4, self.update_hiera('remove', 'orchestrator::missing'))

    def test_missing_value_exits_2(self):
        """add and change without a parameter value exit with 2"""
        self.assertEqual(2, self.update_hiera('change', PARAMETER))
        self.assertEqual(2, self.update_hiera('add', 'orchestrator::missing'))

    def test_unreadable_file_exits_2(self):
        """a hiera file that can't be read exits with 2"""
        missing_file = os.path.join(self.tmp_dir, 'missing.yaml')
        self.assertEqual(2, self.update_hiera('remove', PARAMETER, hiera_file=missing_file))


if __name__ == '__main__':
    unittest.main()
