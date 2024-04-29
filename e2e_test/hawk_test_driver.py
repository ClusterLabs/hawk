#!/usr/bin/python3
# Copyright (C) 2019 SUSE LLC
"""Define Selenium driver related functions and classes to test the HAWK GUI"""

import ipaddress
import time
from distutils.version import LooseVersion as Version

from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException, WebDriverException
from selenium.common.exceptions import ElementNotInteractableException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

from hawk_test_ssh import HawkTestSSH


BIG_TIMEOUT = 6


# Error messages
class Error:
    MAINT_TOGGLE_ERR = "Could not find Switch to Maintenance toggle button for node"
    PRIMITIVE_TARGET_ROLE_ERR = "Couldn't find value [Started] for primitive target-role"
    STONITH_ERR = "Couldn't find stonith-sbd menu to place it in maintenance mode"
    STONITH_ERR_OFF = "Could not find Disable Maintenance Mode button for stonith-sbd"
    CRM_CONFIG_ADVANCED_ATTRIBUTES = "crm_config dropdown box shows the advanced attributes, but shouldn't"


# XPATH constants
class Xpath:
    ANYTHING_OPT_LIST = '//option[contains(@value, "anything")]'
    CLICK_OK_SUBMIT = '//*[@id="modal"]/div/div/form/div[3]/input'
    CLONE_CHILD = '//select[contains(@data-help-filter, ".row.resource") and contains(@name, "clone[child]")]'
    CLONE_DATA_HELP_FILTER = '//a[contains(@data-help-filter, ".clone")]'
    COMMIT_BTN_DANGER = '//button[contains(@class, "btn-danger") and contains(@class, "commit")]'
    DISMISS_MODAL = '//*[@id="modal"]/div/div/div[3]/button'
    DROP_DOWN_FORMAT = '//*[@id="resources"]/div[1]/div[2]/div[2]/table/tbody/tr[{}]/td[6]/div/div'
    EDIT_MONITOR_TIMEOUT = '//*[@id="oplist"]/fieldset/div/div[1]/div[3]/div[2]/div/div/a[1]'
    EDIT_START_TIMEOUT = '//*[@id="oplist"]/fieldset/div/div[1]/div[1]/div[2]/div/div/a[1]'
    EDIT_STOP_TIMEOUT = '//*[@id="oplist"]/fieldset/div/div[1]/div[2]/div[2]/div/div/a[1]'
    GENERATE_REPORT = '//*[@id="generate"]/form/div/div[2]/button'
    GROUP_DATA_FILTER = '//a[contains(@data-help-filter, ".group")]'
    HREF_ALERTS = '//a[contains(@href, "#alerts")]'
    HREF_CONFIGURATION = '//a[contains(@href, "#configurationMenu")]'
    HREF_CONFIG_EDIT = '//a[contains(@href, "config/edit")]'
    HREF_CRM_CONFIG_EDIT = '//a[contains(@href, "crm_config/edit")]'
    HREF_CRM_CONFIG_FENCE_REACTION = '//option[contains(@value, "fence-reaction")]'
    HREF_CRM_CONFIG_NO_QUORUM_POLICY = '//option[contains(@value, "no-quorum-policy")]'
    HREF_CRM_CONFIG_STONITH_ACTION = '//option[contains(@value, "stonith-action")]'
    HREF_CRM_CONFIG_NODE_HEALTH_STRATEGY = '//option[contains(@value, "node-health-strategy")]'
    HREF_CRM_CONFIG_NODE_PLACEMENT_STRATEGY = '//option[contains(@value, "placement-strategy")]'
    HREF_CONSTRAINTS = '//a[contains(@href, "#constraints")]'
    HREF_DASHBOARD = '//a[contains(@href, "/dashboard")]'
    HREF_DELETE_FORMAT = '//a[contains(@href, "{}") and contains(@title, "Delete")]'
    HREF_FENCING = '//a[contains(@href, "#fencing")]'
    HREF_NODES = '//a[contains(@href, "#nodes")]'
    HREF_REPORTS = '//a[contains(@href, "/reports")]'
    HREF_TAGS = '//a[contains(@href, "#tags")]'
    MODAL_MONITOR_TIMEOUT = '//*[@id="modal"]/div/div/form/div[2]/fieldset/div/div[1]/div'
    MODAL_STOP = '//*[@id="modal"]/div/div/form/div[2]/fieldset/div/div[2]/div/div/select/option[6]'
    MODAL_TIMEOUT = '//*[@id="modal"]/div/div/form/div[2]/fieldset/div/div[1]/div/div'
    NODE_DETAILS = '//*[@id="nodes"]/div[1]/div[2]/div[2]/table/tbody/tr[1]/td[5]/div/a[2]'
    NODE_MAINT = '//a[contains(@href, "maintenance") and contains(@title, "Switch to maintenance")]'
    NODE_READY = '//a[contains(@href, "ready") and contains(@title, "Switch to ready")]'
    OCF_OPT_LIST = '//option[contains(@value, "ocf")]'
    OPERATIONS = '//*[@id="nodes"]/div[1]/div[2]/div[2]/table/tbody/tr[1]/td[5]/div/div/button'
    OPT_STONITH = '//option[contains(@value, "stonith-sbd")]'
    RESOURCES_TYPES = '//a[contains(@href, "resources/types")]'
    RSC_OK_SUBMIT = '//input[contains(@class, "submit")]'
    RSC_ROWS = '//*[@id="resources"]/div[1]/div[2]/div[2]/table/tbody/tr'
    STONITH_CHKBOX = '//input[contains(@type, "checkbox") and contains(@value, "stonith-sbd")]'
    STONITH_MAINT_OFF = '//a[contains(@href, "stonith-sbd") and contains(@title, "Disable Maintenance Mode")]'
    STONITH_MAINT_ON = '//a[contains(@href, "stonith-sbd/maintenance_on")]'
    TARGET_ROLE_FORMAT = '//select[contains(@class, "form-control") and contains(@name, "{}[meta][target-role]")]'
    TARGET_ROLE_STARTED = '//option[contains(@value, "tarted")]'
    WIZARDS_BASIC = '//span[contains(@href, "basic")]'

# Move out long strings just to make the code neater
class LongLiterals:
    RSC_DEFAULT_ATTRIBUTES='allow-migrate\ndescription\nfailure-timeout\nis-managed\nmaintenance\nmigration-threshold\nmultiple-active\n\
priority\nremote-addr\nremote-connect-timeout\nremote-node\nremote-port\nrequires\nresource-stickiness\nrestart-type\ntarget-role'
    OP_DEFAULT_ATTRIBUTES='description\nenabled\ninterval\ninterval-origin\non-fail\nrequires\nrole\nstart-delay'
    CRM_CONFIG_ATTRIBUTES='batch-limit\ncluster-delay\ncluster-ipc-limit\ncluster-name\ncluster-recheck-interval\nconcurrent-fencing\n\
dc-deadtime\nenable-acl\nenable-startup-probes\nfence-reaction\nload-threshold\nmaintenance-mode\nmigration-limit\nno-quorum-policy\n\
node-action-limit\nnode-health-base\nnode-health-green\nnode-health-red\nnode-health-strategy\nnode-health-yellow\nnode-pending-timeout\n\
pe-error-series-max\npe-input-series-max\npe-warn-series-max\nplacement-strategy\npriority-fencing-delay\nremove-after-stop\nshutdown-lock\n\
shutdown-lock-limit\nstart-failure-is-fatal\nstonith-action\nstonith-max-attempts\nstonith-timeout\nstonith-watchdog-timeout\nstop-all-resources\n\
stop-orphan-actions\nstop-orphan-resources\nsymmetric-cluster'


class HawkTestDriver:
    def __init__(self, addr='localhost', port='7630', browser='firefox', headless=False, version='15-SP5'):
        self.addr = addr
        self.port = port
        self.driver = None
        self.test_version = version
        self.test_status = True
        self.headless = headless
        self.browser = browser
        if browser == 'firefox':
            self.timeout_scale = 2.5
        else:
            self.timeout_scale = 1

    def _connect(self):
        if self.browser in ['chrome', 'chromium']:
            options = webdriver.ChromeOptions()
            options.add_argument('--no-sandbox')
            options.add_argument('--disable-gpu')
            if self.headless:
                options.add_argument('--headless')
            options.add_argument('--disable-dev-shm-usage')
            self.driver = webdriver.Chrome(chrome_options=options)
        else:
            profile = webdriver.FirefoxProfile()
            profile.accept_untrusted_certs = True
            profile.assume_untrusted_cert_issuer = True
            self.driver = webdriver.Firefox(firefox_profile=profile)
        self.driver.maximize_window()
        return self.driver

    def _close(self):
        self.click_on('Logout')
        self.driver.quit()

    @staticmethod
    def set_test_status(results, testname, status):
        results.set_test_status(testname, status)

    def _do_login(self):
        mainlink = f'https://{self.addr}:{self.port}'
        self.driver.get(mainlink)
        elem = self.find_element(By.NAME, "session[username]")
        if not elem:
            print("ERROR: couldn't find element [session[username]]. Cannot login")
            self.driver.quit()
            return False
        elem.send_keys("hacluster")
        elem = self.find_element(By.NAME, "session[password]")
        if not elem:
            print("ERROR: Couldn't find element [session[password]]. Cannot login")
            self.driver.quit()
            return False
        elem.send_keys("linux")
        elem.send_keys(Keys.RETURN)
        return True

    # Clicks on element identified by clicker if major version from the test is greater or
    # equal than the version to check
    def click_if_major_version(self, version_to_check, text):
        if Version(self.test_version) >= Version(version_to_check):
            self.find_element(By.XPATH, f"//*[text()='{text.capitalize()}']").click()

    # Internal support function click_on partial link test. Sets test_status to False on failure
    def click_on(self, text):
        print(f"INFO: Main page. Click on {text}")
        elem = self.find_element(By.PARTIAL_LINK_TEXT, text)
        if not elem:
            print(f"ERROR: Couldn't find element '{text}'")
            self.test_status = False
            return False
        try:
            elem.click()
        except ElementNotInteractableException:
            # Element is obscured. Wait and click again
            time.sleep(2 * self.timeout_scale)
            elem.click()
        time.sleep(self.timeout_scale)
        return True

    def find_element(self, bywhat, texto, tout=60):
        try:
            elem = WebDriverWait(self.driver,
                                 tout).until(EC.presence_of_element_located((bywhat, texto)))
        except TimeoutException:
            print(f"INFO: {tout} seconds timeout while looking for element [{texto}] by [{bywhat}]")
            return False
        return elem

    def verify_success(self):
        elem = self.find_element(By.CLASS_NAME, 'alert-success', 60 * self.timeout_scale)
        if not elem:
            elem = self.find_element(By.PARTIAL_LINK_TEXT, 'Rename', 5)
            if not elem:
                return False
        return True

    def fill_value(self, field, tout):
        elem = self.find_element(By.NAME, field)
        if not elem:
            print(f"ERROR: couldn't find element [{field}].")
            return
        elem.clear()
        elem.send_keys(f"{tout}")

    def submit_operation_params(self, errmsg):
        self.check_and_click_by_xpath(errmsg, [Xpath.CLICK_OK_SUBMIT])

    def check_edit_conf(self):
        print("INFO: Check edit configuration")
        time.sleep(1)
        if Version(self.test_version) >= Version("15"):
            self.check_and_click_by_xpath("Couldn't find Configuration element", [Xpath.HREF_CONFIGURATION])
        time.sleep(1)
        self.check_and_click_by_xpath("Couldn't find Edit Configuration element", [Xpath.HREF_CONFIG_EDIT])

    # Internal support function to find element(s) by xpath and click them
    # Sets test_status to False on failure.
    def check_and_click_by_xpath(self, errmsg, xpath_exps):
        for xpath in xpath_exps:
            elem = self.find_element(By.XPATH, xpath)
            if not elem:
                print(f"ERROR: Couldn't find element by xpath [{xpath}] {errmsg}")
                self.test_status = False
                return
            time.sleep(5)
            try:
                elem.click()
            except ElementNotInteractableException:
                # Element is obscured. Wait and click again
                time.sleep(10 * self.timeout_scale)
                elem.click()

    # Generic function to perform the tests
    def test(self, testname, results, *extra):
        self.test_status = True    # Clear internal test status before testing
        self._connect()
        if self._do_login():
            time.sleep(5)
            if getattr(self, testname)(*extra):
                self.set_test_status(results, testname, 'passed')
            else:
                self.set_test_status(results, testname, 'failed')
                self.driver.save_screenshot(f'{testname}.png')
        self._close()

    # Set STONITH/sbd in maintenance. Assumes stonith-sbd resource is the last one listed on the
    # resources table
    def test_set_stonith_maintenance(self):
        # wait for page to fully load
        if self.find_element(By.XPATH, Xpath.RSC_ROWS):
            totalrows = len(self.driver.find_elements_by_xpath(Xpath.RSC_ROWS))
            if not totalrows:
                totalrows = 1
            print("TEST: test_set_stonith_maintenance: Placing stonith-sbd in maintenance")
            self.check_and_click_by_xpath(Error.STONITH_ERR, [Xpath.DROP_DOWN_FORMAT.format(totalrows),
                                                              Xpath.STONITH_MAINT_ON, Xpath.COMMIT_BTN_DANGER])
        if self.verify_success():
            print("INFO: stonith-sbd successfully placed in maintenance mode")
            return True
        print("ERROR: failed to place stonith-sbd in maintenance mode")
        return False

    def test_disable_stonith_maintenance(self):
        print("TEST: test_disable_stonith_maintenance: Re-activating stonith-sbd")
        self.check_and_click_by_xpath(Error.STONITH_ERR_OFF, [Xpath.STONITH_MAINT_OFF, Xpath.COMMIT_BTN_DANGER])
        if self.verify_success():
            print("INFO: stonith-sbd successfully reactivated")
            return True
        print("ERROR: failed to reactive stonith-sbd from maintenance mode")
        return False

    def test_view_details_first_node(self):
        print("TEST: test_view_details_first_node: Checking details of first cluster node")
        self.click_on('Nodes')
        self.check_and_click_by_xpath("Click on Nodes", [Xpath.HREF_NODES])
        self.check_and_click_by_xpath("Could not find first node pull down menu", [Xpath.NODE_DETAILS])
        self.check_and_click_by_xpath("Could not find button to dismiss node details popup",
                                      [Xpath.DISMISS_MODAL])
        time.sleep(self.timeout_scale)
        return self.test_status

    def test_clear_state_first_node(self):
        print("TEST: test_clear_state_first_node")
        self.click_on('Nodes')
        self.check_and_click_by_xpath("Click on Nodes", [Xpath.HREF_NODES])
        self.check_and_click_by_xpath("Could not find pull down menu for first cluster node",
                                      [Xpath.OPERATIONS])
        self.click_on('Clear state')
        self.check_and_click_by_xpath("Could not clear the state of the first node",
                                      [Xpath.COMMIT_BTN_DANGER])
        if self.verify_success():
            print("INFO: cleared state of first node successfully")
            time.sleep(2 * self.timeout_scale)
            return True
        print("ERROR: failed to clear state of the first node")
        return False

    def test_set_first_node_maintenance(self):
        print("TEST: test_set_first_node_maintenance: switching node to maintenance")
        self.click_on('Nodes')
        self.check_and_click_by_xpath("Click on Nodes", [Xpath.HREF_NODES])
        self.check_and_click_by_xpath(Error.MAINT_TOGGLE_ERR, [Xpath.NODE_MAINT, Xpath.COMMIT_BTN_DANGER])
        if self.verify_success():
            print("INFO: node successfully switched to maintenance mode")
            return True
        print("ERROR: failed to switch node to maintenance mode")
        return False

    def test_disable_maintenance_first_node(self):
        print("TEST: test_disable_maintenance_first_node: switching node to ready")
        self.click_on('Nodes')
        self.check_and_click_by_xpath("Click on Nodes", [Xpath.HREF_NODES])
        self.check_and_click_by_xpath(Error.MAINT_TOGGLE_ERR, [Xpath.NODE_READY, Xpath.COMMIT_BTN_DANGER])
        if self.verify_success():
            print("INFO: node successfully switched to ready mode")
            return True
        print("ERROR: failed to switch node to ready mode")
        return False

    def test_add_new_cluster(self, cluster):
        print("TEST: test_add_new_cluster")
        self.click_on('Dashboard')
        self.check_and_click_by_xpath("Click on Dashboard", [Xpath.HREF_DASHBOARD])
        elem = self.find_element(By.CLASS_NAME, "btn-default")
        if not elem:
            print("ERROR: Couldn't find class 'btn-default'")
            return False
        elem.click()
        elem = self.find_element(By.NAME, "cluster[name]")
        if not elem:
            print("ERROR: Couldn't find element [cluster[name]]. Cannot add cluster")
            return False
        elem.send_keys(cluster)
        elem = self.find_element(By.NAME, "cluster[host]")
        if not elem:
            print("ERROR: Couldn't find element [cluster[host]]. Cannot add cluster")
            return False
        elem.send_keys(self.addr)
        elem = self.find_element(By.NAME, "submit")
        if not elem:
            print("ERROR: Couldn't find submit button")
            return False
        elem.click()
        while True:
            elem = self.find_element(By.PARTIAL_LINK_TEXT, 'Dashboard')
            try:
                elem.click()
                return True
            except WebDriverException:
                time.sleep(1 + self.timeout_scale)
        return False

    def test_remove_cluster(self, cluster):
        print("TEST: test_remove_cluster")
        self.click_on('Dashboard')
        self.check_and_click_by_xpath("Click on Dashboard", [Xpath.HREF_DASHBOARD])
        elem = self.find_element(By.PARTIAL_LINK_TEXT, cluster)
        if not elem:
            print(f"ERROR: Couldn't find cluster [{cluster}]. Cannot remove")
            return False
        elem.click()
        time.sleep(BIG_TIMEOUT)
        elem = self.find_element(By.CLASS_NAME, 'close')
        if not elem:
            print("ERROR: Cannot find cluster remove button")
            return False
        elem.click()
        time.sleep(2 * self.timeout_scale)
        elem = self.find_element(By.CLASS_NAME, 'cancel')
        if not elem:
            print(f"ERROR: No cancel button while removing cluster [{cluster}]")
        else:
            elem.click()
        time.sleep(self.timeout_scale)
        elem = self.find_element(By.CLASS_NAME, 'close')
        elem.click()
        time.sleep(2 * self.timeout_scale)
        elem = self.find_element(By.CLASS_NAME, 'btn-danger')
        if not elem:
            print(f"ERROR: No OK button found while removing cluster [{cluster}]")
        else:
            elem.click()
        if self.verify_success():
            print(f"INFO: Successfully removed cluster: [{cluster}]")
            return True
        print(f"ERROR: Could not remove cluster [{cluster}]")
        return False

    def test_click_on_history(self):
        print("TEST: test_click_on_history")
        self.click_if_major_version("15", 'troubleshooting')
        if not self.test_status:
            return False
        return self.click_on('History')

    def test_generate_report(self):
        print("TEST: test_generate_report: click on Generate report")
        self.click_if_major_version("15", 'troubleshooting')
        self.click_on('History')
        self.check_and_click_by_xpath("Click on History", [Xpath.HREF_REPORTS])
        if self.find_element(By.XPATH, Xpath.GENERATE_REPORT):
            self.check_and_click_by_xpath("Could not find button for Generate report",
                                          [Xpath.GENERATE_REPORT])
            # Look for actual report
            self.find_element(By.LINK_TEXT, "hawk")
            print("INFO: successfully generated report")
            return True
        print("ERROR: failed to generate report")
        return False

    def test_click_on_command_log(self):
        print("TEST: test_click_on_command_log")
        self.click_if_major_version("15", 'troubleshooting')
        if not self.test_status:
            return False
        return self.click_on('Command Log')

    def test_click_on_status(self):
        print("TEST: test_click_on_status")
        return self.click_on('Status')

    def test_add_primitive(self, primitive):
        print(f"TEST: test_add_primitive: Add Resources: Primitive {primitive}")
        self.click_if_major_version("15", 'configuration')
        self.click_on('Resource')
        self.check_and_click_by_xpath("Click on Add Resource", [Xpath.RESOURCES_TYPES])
        self.click_on('rimitive')
        # Fill the primitive
        elem = self.find_element(By.NAME, 'primitive[id]')
        if not elem:
            print(f"ERROR: Couldn't find element [primitive[id]]. Cannot add primitive [{primitive}].")
            return False
        elem.send_keys(primitive)
        elem = self.find_element(By.NAME, 'primitive[clazz]')
        if not elem:
            print(f"ERROR: Couldn't find element [primitive[clazz]]. Cannot add primitive [{primitive}]")
            return False
        elem.click()
        self.check_and_click_by_xpath("Couldn't find value [ocf] for primitive class",
                                      [Xpath.OCF_OPT_LIST])
        elem = self.find_element(By.NAME, 'primitive[type]')
        if not elem:
            print(f"ERROR: Couldn't find element [primitive[type]]. Cannot add primitive [{primitive}].")
            return False
        elem.click()
        self.check_and_click_by_xpath("Couldn't find value [anything] for primitive type",
                                      [Xpath.ANYTHING_OPT_LIST])
        elem = self.find_element(By.NAME, 'primitive[params][binfile]')
        if not elem:
            print("ERROR: Couldn't find element [primitive[params][binfile]]")
            return False
        elem.send_keys("file")
        # Set start timeout value in 35s
        self.check_and_click_by_xpath("Couldn't find edit button for start operation",
                                      [Xpath.EDIT_START_TIMEOUT, Xpath.MODAL_TIMEOUT])
        self.fill_value('op[timeout]', "35s")
        self.submit_operation_params(". Couldn't Apply changes for start operation")
        # Set stop timeout value in 15s and on-fail
        self.check_and_click_by_xpath("Couldn't find edit button for stop operation",
                                      [Xpath.EDIT_STOP_TIMEOUT, Xpath.MODAL_TIMEOUT])
        self.fill_value('op[timeout]', "15s")
        self.check_and_click_by_xpath("Couldn't add on-fail option for stop operation",
                                      [Xpath.MODAL_STOP])
        self.submit_operation_params(". Couldn't Apply changes for stop operation")
        # Set monitor timeout value in 9s and interval in 13s
        self.check_and_click_by_xpath("Couldn't find edit button for monitor operation",
                                      [Xpath.EDIT_MONITOR_TIMEOUT, Xpath.MODAL_MONITOR_TIMEOUT])
        self.fill_value('op[timeout]', "9s")
        self.fill_value('op[interval]', "13s")
        self.submit_operation_params(". Couldn't Apply changes for monitor operation")
        elem = self.find_element(By.NAME, 'primitive[meta][target-role]')
        if not elem:
            print("ERROR: Couldn't find element [primitive[meta][target-role]]. "
                  f"Cannot add primitive [{primitive}].")
            return False
        time.sleep(1)
        elem.click()
        self.check_and_click_by_xpath(Error.PRIMITIVE_TARGET_ROLE_ERR, [Xpath.TARGET_ROLE_STARTED])
        elem = self.find_element(By.NAME, 'submit')
        if not elem:
            print(f"ERROR: Couldn't find submit button for primitive [{primitive}] creation.")
        else:
            elem.click()
        status = self.verify_success()
        if status:
            print(f"INFO: Successfully added primitive [{primitive}] of class [ocf:heartbeat:anything]")
        else:
            print(f"ERROR: Could not create primitive [{primitive}]")
        return status

    def remove_rsc(self, name):
        print(f"INFO: Remove Resource: {name}")
        self.check_edit_conf()
        # resources list does load again after edit configuration page is loaded
        time.sleep(10)
        self.check_and_click_by_xpath(f"Cannot delete resource [{name}]", [Xpath.HREF_DELETE_FORMAT.format(name)])
        time.sleep(2)
        self.check_and_click_by_xpath(f"Cannot confirm delete of resource [{name}]", [Xpath.COMMIT_BTN_DANGER])
        time.sleep(2)
        self.check_and_click_by_xpath("Couldn't find Edit Configuration element", [Xpath.HREF_CONFIG_EDIT])
        time.sleep(3)
        if not self.test_status:
            print(f"ERROR: One of the elements required to remove resource [{name}] wasn't found")
            return False
        elem = self.find_element(By.XPATH, Xpath.HREF_DELETE_FORMAT.format(name), 5)
        if not elem:
            print(f"INFO: Successfully removed resource [{name}]")
            return True
        print(f"ERROR: Failed to remove resource [{name}]")
        return False

    def test_remove_primitive(self, primitive):
        print(f"TEST: test_remove_primitive: Remove Primitive: {primitive}")
        return self.remove_rsc(primitive)

    def test_remove_clone(self, clone):
        print(f"TEST: test_remove_clone: Remove Clone: {clone}")
        return self.remove_rsc(clone)

    def test_remove_group(self, group):
        print(f"TEST: test_remove_group: Remove Group: {group}")
        return self.remove_rsc(group)

    def test_add_clone(self, clone):
        print(f"TEST: test_add_clone: Adding clone [{clone}]")
        self.click_if_major_version("15", 'configuration')
        self.click_on('Resource')
        self.check_and_click_by_xpath("Click on Add Resource", [Xpath.RESOURCES_TYPES])
        self.check_and_click_by_xpath(f"on Create Clone [{clone}]", [Xpath.CLONE_DATA_HELP_FILTER])
        elem = self.find_element(By.NAME, 'clone[id]')
        if not elem:
            print("ERROR: Couldn't find element [clone[id]]. No text-field where to type clone id")
            return False
        elem.send_keys(clone)
        self.check_and_click_by_xpath(f"while adding clone [{clone}]",
                                      [Xpath.CLONE_CHILD, Xpath.OPT_STONITH, Xpath.TARGET_ROLE_FORMAT.format('clone'),
                                       Xpath.TARGET_ROLE_STARTED, Xpath.RSC_OK_SUBMIT])
        if self.verify_success():
            print(f"INFO: Successfully added clone [{clone}] of [stonith-sbd]")
            return True
        print(f"ERROR: Could not create clone [{clone}]")
        return False

    def test_add_group(self, group):
        print(f"TEST: test_add_group: Adding group [{group}]")
        self.click_if_major_version("15", 'configuration')
        self.click_on('Resource')
        self.check_and_click_by_xpath("Click on Add Resource", [Xpath.RESOURCES_TYPES])
        self.check_and_click_by_xpath(f"while adding group [{group}]", [Xpath.GROUP_DATA_FILTER])
        elem = self.find_element(By.NAME, 'group[id]')
        if not elem:
            print("ERROR: Couldn't find text-field [group[id]] to input group id")
            return False
        elem.send_keys(group)
        self.check_and_click_by_xpath(f"while adding group [{group}]",
                                      [Xpath.STONITH_CHKBOX, Xpath.TARGET_ROLE_FORMAT.format('group'),
                                       Xpath.TARGET_ROLE_STARTED, Xpath.RSC_OK_SUBMIT])
        if self.verify_success():
            print(f"INFO: Successfully added group [{group}] of [stonith-sbd]")
            return True
        print(f"ERROR: Could not create group [{group}]")
        return False

    def test_check_cluster_configuration(self, ssh):
        """
        The test does two things.
        First, it checks that the available resources are correct.
        Second, that the options of select-type resources are correct.
        The test doesn't create those resources.
        """
        print(f"TEST: test_check_cluster_configuration: Check crm options")
        self.click_if_major_version("15", 'configuration')
        self.check_and_click_by_xpath("Click on Cluster Configuration", [Xpath.HREF_CRM_CONFIG_EDIT])

        ### 1.
        # The rsc_defaults and op_defaults are hardcoded in app/models/tableless.rb
        elem = self.find_element(By.NAME, 'temp_crm_config[rsc_defaults]')
        if not elem:
            print(f"ERROR: Couldn't find element temp_crm_config[rsc_defaults]")
            return False
        if elem.text != LongLiterals.RSC_DEFAULT_ATTRIBUTES:
            print(f"ERROR: temp_crm_config[rsc_defaults] has WRONG values")
            return False

        elem = self.find_element(By.NAME, 'temp_crm_config[op_defaults]')
        if not elem:
            print(f"ERROR: Couldn't find element temp_crm_config[op_defaults]")
            return False
        if elem.text != LongLiterals.OP_DEFAULT_ATTRIBUTES:
            print(f"ERROR: temp_crm_config[op_defaults] has WRONG values")
            return False

        # The crm_config is trickier. We should get those attributes from the crm_attribute
        # in the newer versions of pacemaker. If it's an older version of pacemaker
        # let's simply compare it against LongLiterals.CRM_CONFIG_ATTRIBUTES.
        elem = self.find_element(By.NAME, 'temp_crm_config[crm_config]')
        if not elem:
            print(f"ERROR: Couldn't find element temp_crm_config[crm_config]")
            return False

        lst = elem.text.split('\n')
        for a in ['cluster-name', 'stonith-timeout']:
            if a not in lst:
                lst.append(a)
        lst.sort()

        # First try to get the values from the crm_attribute
        if ssh.is_valid_command("crm_attribute --list-options=cluster --all --output-as=xml"):
            if not ssh.check_cluster_conf_ssh("crm_attribute --list-options=cluster --all --output-as=xml | grep 'advanced=\"0\"' | sed 's/.*name=\"*\\([^\\\"]*\\)\".*/\\1/'", lst, silent=True, anycheck=False):
                print(f'ERROR: {Error.CRM_CONFIG_ADVANCED_ATTRIBUTES}')
                return False
        # If the crm_attribute too old for this
        else:
            for a in lst:
                if a not in LongLiterals.CRM_CONFIG_ATTRIBUTES:
                    print(f'ERROR: {Error.CRM_CONFIG_ADVANCED_ATTRIBUTES}, attr: {a}')
                    return False

        ### 2.
        # Show out all but fence-reaction select-type resources
        # (fence-reaction is a string the pacemaker-controld
        # and a select in the crm_attribute. Let's not overengineer.)
        elem.click()
        for xref in [Xpath.HREF_CRM_CONFIG_NO_QUORUM_POLICY,
                    Xpath.HREF_CRM_CONFIG_STONITH_ACTION,
                    Xpath.HREF_CRM_CONFIG_NODE_HEALTH_STRATEGY,
                    Xpath.HREF_CRM_CONFIG_NODE_PLACEMENT_STRATEGY]:
            self.check_and_click_by_xpath(f'Couldn\'t find {xref} resource in the drop-down list',
                                    [xref])
            time.sleep(1)

        # ["<resource name>", ["<option1>", "<option2>,..."]]
        for check_options in [ ["no-quorum-policy", ["stop", "freeze", "ignore", "demote", "suicide"]],
                            ["stonith-action", ["reboot", "off", "poweroff"]],
                            ["node-health-strategy", ["none", "migrate-on-red", "only-green", "progressive", "custom"]],
                            ["placement-strategy", ["default", "utilization", "minimal", "balanced"]]]:
            elem = self.find_element(By.NAME, f'crm_config[crm_config][{check_options[0]}]')
            if not elem:
                print(f'ERROR: Couldn\'t find {check_options[0]}')
                return False

            lst = elem.text.split('\n')
            lst.sort()
            check_options[1].sort()
            if lst != check_options[1]:
                print(f'ERROR: {check_options[0]} options. Expected: {lst}, are: {check_options[1]}')
                return False

        time.sleep(self.timeout_scale)
        return self.test_status


    def test_click_around_edit_conf(self):
        print("TEST: test_click_around_edit_conf")
        print("TEST: Will click on Constraints, Nodes, Tags, Alerts and Fencing")
        self.check_edit_conf()

        click_list = [
            Xpath.HREF_CONSTRAINTS, Xpath.HREF_NODES, Xpath.HREF_TAGS,
            Xpath.HREF_ALERTS, Xpath.HREF_FENCING
        ]

        self.check_and_click_by_xpath("while checking around edit configuration", click_list)
        return self.test_status

    def test_add_virtual_ip(self, virtual_ip):
        print("TEST: test_add_virtual_ip: Add virtual IP from the Wizard")
        self.click_if_major_version("15", 'configuration')
        broadcast = str(ipaddress.IPv4Network(virtual_ip, False).broadcast_address)
        virtual_ip, netmask = virtual_ip.split('/')
        self.find_element(By.LINK_TEXT, 'Wizards').click()
        self.check_and_click_by_xpath('while clicking Basic', [Xpath.WIZARDS_BASIC])
        self.click_on('Virtual IP')
        self.fill_value('virtual-ip.id', 'vip')
        self.fill_value('virtual-ip.ip', virtual_ip)
        self.fill_value('virtual-ip.cidr_netmask', netmask)
        self.fill_value('virtual-ip.broadcast', broadcast)
        elem = self.find_element(By.NAME, 'submit')
        if not elem:
            print("ERROR: Couldn't find [Verify] button on Virtual IP Wizard")
            return False
        elem.click()
        time.sleep(3)
        elem = self.find_element(By.NAME, 'submit')
        if not elem:
            print("ERROR: Couldn't find [Apply] button on Virtual IP Wizard")
            return False
        elem.click()
        time.sleep(3)
        # Check that we can connect to the Wizard on the virtual IP
        old_addr = self.addr
        self.addr = virtual_ip
        self._close()
        time.sleep(10)
        self._connect()
        try:
            self._do_login()
        except WebDriverException:
            print("ERROR: Could not connect to virtual IP")
            # Reset address to old_addr so remaining tests can connect to HAWK
            self.addr = old_addr
            return False
        print("INFO: Successfully added virtual IP")
        # Reset address to old_addr
        self.addr = old_addr
        return True

    def test_remove_virtual_ip(self):
        print("TEST: test_remove_virtual_ip: Remove virtual IP")
        return self.remove_rsc("vip")

    def test_fencing(self):
        print("TEST: test_fencing")
        self.click_on('Nodes')
        self.check_and_click_by_xpath("Click on Nodes", [Xpath.OPERATIONS])
        self.click_on('Fence')
        self.check_and_click_by_xpath("Could not fence first node",
                                      [Xpath.COMMIT_BTN_DANGER])
        if self.verify_success():
            print("INFO: Master node successfully fenced")
            return True
        print("ERROR: Could not fence master node")
        return False
