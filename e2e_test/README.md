# Hawk end to end tests.

This Docker image runs a set of Selenium tests for testing [Hawk](https://github.com/ClusterLabs/hawk/)

The following tests are executed by openQA during ci regularly.

As developer you can execute them manually when you do an update on hawk.

# Pre-requisites:

* docker
* 2 Hawk vms running 
 (normally it is a cluster)
See https://github.com/SUSE/pacemaker-deploy  for deploying hawk


# Quickstart:

1) Create the docker image
`docker build . -t hawk_test `

2) Run the tests with:
``` docker run --ipc=host hawk_test -H 10.162.32.175 -S 10.162.29.122 -t 15 -s linux --xvfb ```

Notes:
  - You may want to add `--net=host` if you have problems with DNS resolution.

## Dependencies

- OS packages:
  - Xvfb (optional)
  - Docker (optional)
  - Firefox
  - [Geckodriver](https://github.com/mozilla/geckodriver/releases)
  - Chromium (optional)
  - [Chromedriver](https://chromedriver.chromium.org/downloads) (optional)
  - Python 3
- Python packages:
  - paramiko
  - selenium
  - PyVirtualDisplay

## Options

```
  -h, --help            show this help message and exit
  -b {firefox,chrome,chromium}, --browser {firefox,chrome,chromium}
                        Browser to use in the test
  -H HOST, --host HOST  Host or IP address where HAWK is running
  -S SLAVE, --slave SLAVE
                        Host or IP address of the slave
  -I VIRTUAL_IP, --virtual-ip VIRTUAL_IP
                        Virtual IP address in CIDR notation
  -P PORT, --port PORT  TCP port where HAWK is running
  -p PREFIX, --prefix PREFIX
                        Prefix to add to Resources created during the test
  -t TEST_VERSION, --test-version TEST_VERSION
                        Test SLES Version. Ex: 12-SP3, 12-SP4, 15, 15-SP1
  -s SECRET, --secret SECRET
                        root SSH Password of the HAWK node
  -r RESULTS, --results RESULTS
                        Generate hawk_test.results file for use with openQA.
  --xvfb                Use Xvfb. Headless mode
```

## FAQ

- Why Xvfb?
  - The `-headless` in both browsers still have bugs, specially with modal dialogs.
  - Having Xvfb prevents it from connecting to our X system.
- Why docker?
  - The Docker image packs the necessary dependencies in such a way that fits the compatibility matrix between Python, Selenium, Firefox (and Geckodriver) & Chromium (and Chromedriver).
