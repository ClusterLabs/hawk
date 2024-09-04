#!/usr/bin/python3
# Copyright (C) 2019 SUSE LLC
"""Define SSH related functions to test the HAWK GUI"""

from distutils.version import LooseVersion as Version
import paramiko


class HawkTestSSH:
    '''
    Class for Hawk test SSH connection via paramkio library
    '''
    def __init__(self, hostname, secret=None):
        '''
        Constructor function to initialize paramiko ssh connection with key or password
        Args:
            hostname (str): target hostname for SSH connection
            secret (str): password strings for SSH connection
        '''
        self.ssh = paramiko.SSHClient()
        self.ssh.load_system_host_keys()
        self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy)
        self.ssh.connect(hostname=hostname.lower(), username="root", password=secret)

    def is_valid_command(self, command):
        '''
        Execute command via SSH connection and return code
        Args:
            command (str): input command
        Returns:
            boolean : True or False
        '''
        _, out, err = self.ssh.exec_command(command)
        out, err = map(lambda f: f.read().decode().rstrip('\n'), (out, err))
        if err:
            return False
        return True

    def check_cluster_conf_ssh(self, command, mustmatch, silent=False, anycheck=False):
        '''
        Execute command via SSH connection and compare if its output matches expectation
        Args:
            command (str): input command
            mustmatch (object): expected string or list
            silent (boolean): print info or not
            anycheck (boolean): if match at least one element in the list
        Raises:
            ValueError: No value matches expected string or list
        Return:
            boolean or matched value
        '''
        _, out, err = self.ssh.exec_command(command)
        out, err = map(lambda f: f.read().decode().rstrip('\n'), (out, err))
        if not silent:
            print(f"INFO: ssh command [{command}] got output [{out}] and error [{err}]")
        if err:
            print(f"ERROR: got an error over SSH: [{err}]")
            return False
        if isinstance(mustmatch, str):
            return mustmatch in out
        if isinstance(mustmatch, list) and anycheck:
            # Output has to match at least one element in the list
            return any(_ in out for _ in mustmatch)
        if isinstance(mustmatch, list) and not anycheck:
            # Output has to match all elements in list
            return all(_ in out for _ in mustmatch)
        raise ValueError("check_cluster_conf_ssh: mustmatch must be str or list")

    @staticmethod
    def set_test_status(results, test, status):
        '''
        Static method to set test status
        Args:
            results(obj): instance of class ResultSet
            test(str): test case name
            status(str): 'passed' or 'failed'
        '''
        results.set_test_status(test, status)

    def verify_stonith_in_maintenance(self, results):
        '''
        Verify stonith-sbd is unmanaged or maintenance and update test status
        Args:
            results(obj): instance of class ResultSet
        Return:
            boolean:
                True when stonith-sbd is unmanaged/maintenance
                False when stonith-sbd is not unmanaged nor in maintenance
        '''
        print("TEST: verify_stonith_in_maintenance")
        if self.check_cluster_conf_ssh("crm status | grep stonith-sbd", ["unmanaged", "maintenance"], anycheck=True):
            print("INFO: stonith-sbd is unmanaged/maintenance")
            self.set_test_status(results, 'verify_stonith_in_maintenance', 'passed')
            return True
        print("ERROR: stonith-sbd is not unmanaged nor in maintenance but should be")
        self.set_test_status(results, 'verify_stonith_in_maintenance', 'failed')
        return False

    def verify_node_maintenance(self, results):
        '''
        Verify if node is maintenance mode
        Args:
            results(obj): instance of class ResultSet
        Return:
            boolean:
                True when node is in maintenance mode
                False when node is in maintenance mode
        '''
        print("TEST: verify_node_maintenance: check cluster node is in maintenance mode")
        if self.check_cluster_conf_ssh("crm status | grep -i node", "maintenance"):
            print("INFO: cluster node set successfully in maintenance mode")
            self.set_test_status(results, 'verify_node_maintenance', 'passed')
            return True
        print("ERROR: cluster node failed to switch to maintenance mode")
        self.set_test_status(results, 'verify_node_maintenance', 'failed')
        return False

    def verify_primitive(self, primitive, version, results):
        '''
        Verify if primitive exists
        Args:
            primitive(str): primitive
            version(str): OS version
            results(obj): instance of class ResultSet
        Return:
            boolean:
                True when primitive is defined in configuration
                False when configuration is not defined in configuration
        '''
        print(f"TEST: verify_primitive: check primitive [{primitive}] exists")
        matches = [f"{primitive} Dummy", "op start timeout=35s",
                   "op monitor timeout=9s interval=13s", "meta target-role=Started"]
        if Version(version) < Version('15'):
            matches.append("op stop timeout=15s")
        else:
            matches.append("op stop timeout=15s on-fail=stop")
        if self.check_cluster_conf_ssh("crm configure show", matches):
            print(f"INFO: primitive [{primitive}] correctly defined in the cluster configuration")
            self.set_test_status(results, 'verify_primitive', 'passed')
            return True
        print(f"ERROR: primitive [{primitive}] missing from cluster configuration")
        self.set_test_status(results, 'verify_primitive', 'failed')
        return False

    def verify_primitive_removed(self, primitive, results):
        '''
        Verify if primitive is removed
        Args:
            primitive(str): primitive
            results(obj): instance of class ResultSet
        Return:
            boolean:
                True when primitive is removed
                False when configuration is not removed
        '''
        print(f"TEST: verify_primitive_removed: check primitive [{primitive}] is removed")
        if self.check_cluster_conf_ssh("crm resource status | grep ocf::heartbeat:Dummy", ''):
            print("INFO: primitive successfully removed")
            self.set_test_status(results, 'verify_primitive_removed', 'passed')
            return True
        print(f"ERROR: primitive [{primitive}] still present in the cluster while checking with SSH")
        self.set_test_status(results, 'verify_primitive_removed', 'failed')
        return False
