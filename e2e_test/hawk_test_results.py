#!/usr/bin/python3
# Copyright (C) 2019 SUSE LLC
"""Define classes and functions to handle results in HAWK GUI test"""

import time
import json

from hawk_test_driver import HawkTestDriver
from hawk_test_ssh import HawkTestSSH


class ResultSet:
    '''
    Class for handling results data in Hawk GUI test
    '''
    def __init__(self):
        '''
        Constructor function to initialize mandatory data for results_set
        '''
        # list my_tests stores callable functions of test cases
        # from HawkTestDriver methods starts with test_
        self.my_tests = []
        self.start_time = time.time()
        for func in dir(HawkTestDriver):
            if func.startswith('test_') and callable(getattr(HawkTestDriver, func)):
                self.my_tests.append(func)
        # dict results_set initialize
        self.results_set = {'tests': [], 'info': {}, 'summary': {}}
        # prepare results for each test case
        for test in self.my_tests:
            auxd = {'name': test, 'test_index': 0, 'outcome': 'failed'}
            self.results_set['tests'].append(auxd)
        # set initial values for self.results_set['info']
        self.results_set['info']['timestamp'] = time.time()
        with open('/etc/os-release', encoding="utf-8") as file:
            lines = file.read().splitlines()
        osrel = {k: v[1:-1] for (k, v) in [line.split('=') for line in lines if '=' in line]}
        self.results_set['info']['distro'] = osrel['PRETTY_NAME']
        self.results_set['info']['results_file'] = 'hawk_test.results'
        # set initial values for self.results_set['summary']
        self.results_set['summary']['duration'] = 0
        self.results_set['summary']['passed'] = 0
        self.results_set['summary']['num_tests'] = len(self.my_tests)

    def add_ssh_tests(self):
        '''
        Append callable functions of test cases
        from HawkTestSSH methods starts with verify_
        '''
        for func in dir(HawkTestSSH):
            if func.startswith('verify_') and callable(getattr(HawkTestSSH, func)):
                self.my_tests.append(func)
                auxd = {'name': str(func), 'test_index': 0, 'outcome': 'failed'}
                self.results_set['tests'].append(auxd)
        self.results_set['summary']['num_tests'] = len(self.my_tests)

    def logresults(self, filename):
        '''
        Write results with json format converted from dict
        Args:
            filename (str): filename for storing results
        '''
        with open(filename, "w", encoding="utf-8") as resfh:
            resfh.write(json.dumps(self.results_set))

    def set_test_status(self, testname, status):
        '''
        Store result data: status, duration and timestamp
        Args:
            testname (str): test case name
            status (str):   passed, failed, skipped
        Raises:
            ValueError: status cannot match requirement
        '''
        if status not in ['passed', 'failed', 'skipped']:
            raise ValueError('test status must be either [passed] or [failed]')
        if status == 'passed' and \
                self.results_set['tests'][self.my_tests.index(testname)]['outcome'] != 'passed':
            self.results_set['summary']['passed'] += 1
        elif status == 'failed' and \
                self.results_set['tests'][self.my_tests.index(testname)]['outcome'] != 'failed':
            self.results_set['summary']['passed'] -= 1
        elif status == 'skipped' and \
                self.results_set['tests'][self.my_tests.index(testname)]['outcome'] != 'skipped':
            self.results_set['summary']['num_tests'] -= 1
        self.results_set['tests'][self.my_tests.index(testname)]['outcome'] = status
        self.results_set['summary']['duration'] = time.time() - self.start_time
        self.results_set['info']['timestamp'] = time.time()

    def get_failed_tests_total(self):
        '''
        Returns (str):
            The number of failed tests
        '''
        return self.results_set['summary']['num_tests'] - self.results_set['summary']['passed']
