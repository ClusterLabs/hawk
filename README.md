# HA Web Konsole (Hawk)

<a href="https://travis-ci.org/ClusterLabs/hawk">![Build Status](https://travis-ci.org/ClusterLabs/hawk.svg?branch=master)</a>
<a href="https://codeclimate.com/github/ClusterLabs/hawk">![Code Climate](https://codeclimate.com/github/ClusterLabs/hawk/badges/gpa.svg)</a>
<a href="http://hawk-guide.readthedocs.org/">![Documentation](https://readthedocs.org/projects/hawk-guide/badge/?style=flat)</a>

Hawk provides a web interface for High Availability clusters managed
by the Pacemaker cluster resource manager. The current goal of the
project is to provide a complete management interface to the HA
cluster, both in the form of a flexible REST API as well as a modern
client frontend using the API.

http://hawk-ui.github.io

  - [Features](doc/features.md)
  - [Build Dependencies](#build-dependencies)
  - [Release](doc/release.md)
  - [Installation](#installation-and-deployment)
  - [Devel notes](#devel)
  - [Testing](#testing)

## Build Dependencies

The exact versions specified here may not be accurate. Also, note that
Hawk also requires the rubygems listed in `hawk/Gemfile`.

* ruby >= 2.2
* crmsh >= 3.0.0
* hawk-apiserver
* graphviz
* graphviz-gd
* dejavu
* pacemaker >= 1.1.8
* bundler
* iproute2

For details about the Hawk API server, see the separate repository at Github:

* https://github.com/ClusterLabs/hawk-apiserver

## Installation and deployment:

On openSUSE use following commands:

```bash
zypper install hawk2
crm cluster init
```
Once initialized, go to `https://<IP>:7630/`.

### Deploy:

use the following project for deploying hawk  https://github.com/SUSE/pacemaker-deploy


# Devel


### Puma server configuration

You can change the configurations of both instances of the Puma sever through
the configuration file in `hawk/config/puma.rb`. You can also pass options directly
through environment variables.

Please also note that the Puma server is configured to use a maximum number of
16 threads withing one worker in clustered mode. This application is thread safe
and you can customize this through the puma.rb file. 

For further information about threads and workers in Puma, please take a look at
this great article by Heroku: [Puma web server article](https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server)

### Hacking hawk tools

Hawk's tools are the programs under the `hawk/tools` folder
(`hawk_chkpwd` and `hawk_invoke`). 

```bash
ls /usr/sbin/hawk_* -l+ +
-rwsr-x--- 1 root haclient 9884 2011-04-14 22:56 /usr/sbin/hawk_chkpwd+
-rwsr-x--- 1 root haclient 9928 2011-04-14 22:56 /usr/sbin/hawk_invoke+
```

`hawk_chkpwd` is almost identical to `unix2_chkpwd`, except it restricts
acccess to users in the `haclient` group, and doesn't inject any delay
when invoked by the `hacluster` user (which is the user the Hawk web
server instance runs as).

`hawk_invoke` allows the `hacluster` user to run a small assortment
of Pacemaker CLI tools as another user in order to support Pacemaker's
ACL feature. It is used by Hawk when performing various management
tasks.

# testing:

In addition to unit test we provide End to end test for a Hawk validation.

See e2e_test/README.md for full documentation
