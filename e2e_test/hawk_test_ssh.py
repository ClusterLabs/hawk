#!/usr/bin/python3
# Copyright (C) 2019 SUSE LLC
"""Define SSH related functions to test the HAWK GUI"""

from distutils.version import LooseVersion as Version
import paramiko


class HawkTestSSH:
    def __init__(self, hostname, secret=None):
        self.ssh = paramiko.SSHClient()
        self.ssh.load_system_host_keys()
        self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy)
        self.ssh.connect(hostname=hostname.lower(), username="root", password=secret)

    def check_cluster_conf_ssh(self, command, mustmatch):
        _, out, err = self.ssh.exec_command(command)
        out, err = map(lambda f: f.read().decode().rstrip('\n'), (out, err))
        print("INFO: ssh command [%s] got output [%s] and error [%s]" % (command, out, err))
        if err:
            print("ERROR: got an error over SSH: [%s]" % err)
            return False
        if isinstance(mustmatch, str):
            if mustmatch:
                if mustmatch in out:
                    return True
                return False
            return out == mustmatch
        if isinstance(mustmatch, list):
            for exp in mustmatch:
                if exp not in out:
                    return False
            return True
        raise ValueError("check_cluster_conf_ssh: mustmatch must be str or list")

    @staticmethod
    def set_test_status(results, test, status):
        results.set_test_status(test, status)

    def verify_stonith_in_maintenance(self, results):
        print("TEST: verify_stonith_in_maintenance")
        if self.check_cluster_conf_ssh("crm status | grep stonith-sbd", "unmanaged"):
            print("INFO: stonith-sbd is unmanaged")
            self.set_test_status(results, 'verify_stonith_in_maintenance', 'passed')
            return True
        print("ERROR: stonith-sbd is not unmanaged but should be")
        self.set_test_status(results, 'verify_stonith_in_maintenance', 'failed')
        return False

    def verify_node_maintenance(self, results):
        print("TEST: verify_node_maintenance: check cluster node is in maintenance mode")
        if self.check_cluster_conf_ssh("crm status | grep -i node", "maintenance"):
            print("INFO: cluster node set successfully in maintenance mode")
            self.set_test_status(results, 'verify_node_maintenance', 'passed')
            return True
        print("ERROR: cluster node failed to switch to maintenance mode")
        self.set_test_status(results, 'verify_node_maintenance', 'failed')
        return False

    def verify_primitive(self, myprimitive, version, results):
        print("TEST: verify_primitive: check primitive [%s] exists" % myprimitive)
        matches = ["%s anything" % myprimitive, "binfile=file", "op start timeout=35s",
                   "op monitor timeout=9s interval=13s", "meta target-role=Started"]
        if Version(version) < Version('15'):
            matches.append("op stop timeout=15s")
        else:
            matches.append("op stop timeout=15s on-fail=stop")
        if self.check_cluster_conf_ssh("crm configure show", matches):
            print("INFO: primitive [%s] correctly defined in the cluster configuration" %
                  myprimitive)
            self.set_test_status(results, 'verify_primitive', 'passed')
            return True
        print("ERROR: primitive [%s] missing from cluster configuration" % myprimitive)
        self.set_test_status(results, 'verify_primitive', 'failed')
        return False

    def verify_primitive_removed(self, myprimitive, results):
        print("TEST: verify_primitive_removed: check primitive [%s] is removed" % myprimitive)
        if self.check_cluster_conf_ssh("crm resource status | grep ocf::heartbeat:anything", ''):
            print("INFO: primitive successfully removed")
            self.set_test_status(results, 'verify_primitive_removed', 'passed')
            return True
        print("ERROR: primitive [%s] still present in the cluster while checking with SSH" %
              myprimitive)
        self.set_test_status(results, 'verify_primitive_removed', 'failed')
        return False
