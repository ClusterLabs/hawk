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

## Table of contents

- [HA Web Konsole (Hawk)](#ha-web-konsole-hawk)
  - [Table of contents](#table-of-contents)
  - [Overview](#overview)
  - [API](#api)
  - [Documentation](#documentation)
  - [Screenshots](#screenshots)
  - [Features](#features)
    - [Resource Management](#resource-management)
    - [Multi-cluster Dashboard](#multi-cluster-dashboard)
    - [History Explorer](#history-explorer)
    - [Configuration](#configuration)
    - [Wizards](#wizards)
    - [View Configuration and Graph](#view-configuration-and-graph)
    - [Command Log](#command-log)
    - [Access Control Lists](#access-control-lists)
    - [Simulator](#simulator)
  - [Build Dependencies](#build-dependencies)
    - [Dependencies](#dependencies)
  - [Installation](#installation)
    - [Installing The Easy Way](#installing-the-easy-way)
    - [Packaging Notes](#packaging-notes)
  - [A Note on SSL Certificates](#a-note-on-ssl-certificates)
  - [Hacking Hawk](#hacking-hawk)
    - [Preconfigured Vagrant environment](#preconfigured-vagrant-environment)
    - [Changing the Vagrant configuration file](#changing-the-vagrant-configuration-file)
    - [Web server instances](#web-server-instances)
    - [Puma server configuration](#puma-server-configuration)
    - [Hacking hawk tools](#hacking-hawk-tools)
  - [Questions, Feedback, etc.](#questions-feedback-etc)
    - [Footnotes](#footnotes)

## Overview

Hawk runs on every node in the cluster, so that you can just point
your web browser at any node to access it. E.g.:

https://your-cluster-node:7630/

Hawk is always accessed via HTTPS, and requires users to log in prior
to providing access to the cluster. The same user privilege rules
apply as for Pacemaker itself: You need to log in as a user in the
`haclient` group. The easiest thing to do is to assign a password to
the `hacluster` user, and then to log in using that account. Note that
you will need to configure this user account on every node that you
will use Hawk on.

For more fine-grained control over access to the cluster, you can
create multiple user accounts and configure Access Control Lists (ACL)
for those users. These access control rules are available directly
from the Hawk user interface.

Once logged in, you will see a status view displaying the current
state of the cluster. All the configured cluster resources are shown
together with their status, as well as a general state of the cluster
and a list of recent cluster events (if any).

The navigation menu on the left hand side provides access to the
additional features of Hawk, such as the history explorer, the
multi-cluster dashboard and configuration management. On the top right
of the screen you can enable or disable the simulator, configure user
preferences and log out of the cluster.

Resource management operations (start, stop, online, standby, etc.)
can be performed using the menu of operations next to the resource in
the status view.

## API

Hawk is being restructured to provide a cleaner separation between the
frontend and the backend. As a first step towards this goal, Hawk now
uses its own small API proxy daemon as a web server, which is
maintained as a separate project:

* [API Server Repository](https://github.com/krig/hawk-apiserver)

## Documentation

* [Website](http://hawk-ui.github.io)
* [The Hawk Guide](http://hawk-guide.readthedocs.org/en/latest/)
* [SUSE Linux Enterprise High Availability Extension Documentation](http://www.suse.com/documentation/sle_ha/book_sleha/?page=/documentation/sle_ha/book_sleha/data/cha_ha_configuration_hawk.html)

## Screenshots

![Status](/screens/hawk_status.png)
![Wizard](/screens/hawk_wizards.png)

## Features

Note that this list of features is not complete, and is intended only
as a rough guide to the Hawk user interface.

### Resource Management

From the status view of Hawk, you can control the state of individual
resources or resource groups, start / stop / promote / demote. You can
also migrate resources to and away from specific nodes, clean up
resources after failure and show a list of recent events for the
resource.

On the status page you can also manage nodes including setting node
attributes and displaying recent events related to the specific node.

Additionally, if there are any tickets configured (requires the use of
geo clustering via booth <sup>[1](#footnote1)</sup>),
these are also displayed in the status view  and can be managed in a
similar fashion to resources.

### Multi-cluster Dashboard

The Dashboard can be used to monitor the local cluster, displaying a
blinkenlights-style overview of all resources as well as any recent
failures that may have occurred. It is also possible to configure
access to remote clusters, so that multiple clusters can be monitored
from a single interface. This can be useful as a HUD in an operations
center, or when using geo clustering.

Hawk can also run in an **offline mode**, where you run Hawk on a
non-cluster machine which monitors one or more remote clusters.

### History Explorer

The history explorer is a tool for collecting and downloading cluster
reports, which include logs and other information for a certain
timeframe. The history explorer is also useful for analysing such
cluster reports. You can either upload a previously generated cluster
report for analysis, or generate one on the fly.

Once uploaded, you can scroll through all of the cluster events that
took place in the time frame covered by the report. For each event,
you can see the current cluster configuration, logs from all cluster
nodes and a transition graph showing exactly what happened and why.

### Configuration

Hawk makes it easy to configure both resources, groups of resources,
constraints and tags. You can also configure resource templates to be
reused later, and cloned resources that are active on multiple nodes
at once.

### Wizards

Cluster wizards are useful for creating more complicated
configurations in a single process. The wizards vary in complexity
from simply configuring a single virtual IP address to configuring
multiple resources together with constraints, in multiple steps and
including package installation, configuration and setup.

### View Configuration and Graph

From the web interface you can view the current cluster configuration
in the `crm` shell syntax or as XML. You can also generate a graph
view of the resources and constraints configured in the cluster.

### Command Log

To make the transition between using the web interface and the command
line interface easier, Hawk provides a command log showing a list of
recent commands executed by the web interface. A user who is learning
to configure a Pacemaker cluster can start by using the web interface,
and learn how to use the command line in the process.

### Access Control Lists

Pacemaker supports fine-grained access control to the configuration
based on user roles. These roles can be viewed and configured directly
from the web interface. Using the ACL rules, you can for example
create unprivileged user accounts that are able to log in and view the
state of the cluster, but cannot edit resources.

### Simulator

Hawk features a cluster simulation mode. Once enabled, any changes to
the cluster are not applied directly. Instead, events such as resource
failure or node failure can be simulated, and the user can see what
the resulting cluster response would be. This can be very useful when
configuring constraints, to ensure that the rules work as intended.

## Build Dependencies

The exact versions specified here may not be accurate. Also, note that
Hawk also requires the rubygems listed in `hawk/Gemfile`.

* ruby >= 2.2
* pam-devel

### Dependencies

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

* https://github.com/krig/hawk-apiserver

## Installation

Hawk is a Ruby on Rails app which runs using the Puma web server
(http://puma.io/).

For details on the rubygems used by hawk, see the gemfile in
`hawk/Gemfile`.

### Installing The Easy Way

If you are running openSUSE Tumbleweed, you are in luck. All you have
to do is install the hawk2 package and then initialize the HA cluster:

```bash
zypper install hawk2
crm cluster init
```
Once initialized, go to `https://<IP>:7630/`.

### Packaging Notes

For anyone looking to package Hawk for distributions, the best approach is probably to look at the RPM packaging at the SUSE Open Build Service and begin from there:

* https://build.opensuse.org/package/show/network:ha-clustering:Factory/hawk2

The main difficulty will probably be deciding how to package the Ruby gems. Hawk used to have an installation mode in which all Ruby gems were bundled into a single RPM package, but for maintainability reasons we decided to split each rubygem into its own package.

## A Note on SSL Certificates

The Hawk init script will automatically generate a self-signed SSL
certificate, in `/etc/hawk/hawk.pem`.  If you want
to use your own certificate, replace `hawk.key` and `hawk.pem` with
your certificate. For browsers to accept this certificate, the node running Hawk will need to be accessed via the domain name specified in the certificate.

## Hacking Hawk
### Preconfigured Vagrant environment

To hack on Hawk we recommend to use the vagrant setup. There is a
Vagrantfile attached, which creates a three-node cluster with a basic
configuration suitable for development and testing.

To be prepared for getting our vagrant setup running you need to follow
some steps.

* Install the vagrant package from http://www.vagrantup.com/downloads.html.
* Install `libvirt` and `kvm` to actually host the Hawk virtual machine.

Out of the box, `vagrant` is configured to synchronize the working
folder to `/vagrant` in the virtual machines using NFS. For this to
work properly, the `vagrant-bindfs` plugin is necessary.

Install it using the following command:

```bash
vagrant plugin install vagrant-bindfs
```

* Make sure you have the libvirt-plugin installed:

```bash
vagrant plugin install vagrant-libvirt
```

This is all you need to prepare initially to set up the vagrant environment,
now you can simply start the virtual machine with `vagrant up` and start
an ssh session with `vagrant ssh webui`. If you want to access
the source within the virtual machine you have to switch to the `/vagrant`
directory.

### Changing the Vagrant configuration file

Default Vagrant parameters are kept in a separate YAML file `vconf.yml`.
This file is also read by the Salt provisioner, the values are parsed and
treated as pillar data. Therefor It's possible to change the
default behavior of Vagrant and Salt by tweaking `vconf.yml` file, (e.g. running
on a remote Libvirt server, changing to master/minions setup, changing the ip
addresses of the nodes, etc).

### Web server instances

You can access the Hawk web interface based on the git source through
`https://localhost:3000` now. If you want to access the version installed
through packages you can reach it through `https://localhost:7630`.

In fact, within the Vagrant environment, there are two instances of
the Hawk interface running. The first one is accessible through
`https://localhost:7630`, with `/usr/share/hawk` as the root
directory. This instance is launched by default as a production server
when installing hawk through the package manager or when launching the
vagrant environment. It is used to monitor and manage the cluster in
the real production environment.

The commands used to control this server are:

```bash
$ vagrant ssh webui
vagrant@webui:~> sudo systemctl start hawk
vagrant@webui:~> sudo systemctl stop hawk
vagrant@webui:~> sudo systemctl restart hawk
vagrant@webui:~> sudo systemctl status hawk
```

The other instance is used for development purposes. Its root directory is
`/vagrant/hawk`. That's because the /vagrant folder is synced with the host
machine's working folder (the local git repository), so any changes in that folder
is detected instantly by this server instance in the guest machine.
This instance is accessible through `https://localhost:3000`.
Also, You can find installed on the development VM a script called `hawk`
(hawk/bin/hawk), which can be used to control the development instance of hawk:

```bash
$ vagrant ssh webui
vagrant@webui:~> export PATH=/vagrant/hawk/bin:$PATH
vagrant@webui:~> hawk status
vagrant@webui:~> hawk log
vagrant@webui:~> hawk apilog
vagrant@webui:~> hawk start
vagrant@webui:~> hawk stop
vagrant@webui:~> hawk restart
```

### Puma server configuration

You can change the configurations of both instances of the Puma sever through
the configuration file in `hawk/config/puma.rb`. You can also pass options directly
through environment variables.

Please also note that the Puma server is configured to use a maximum number of
16 threads withing one worker in clustered mode. This application is thread safe
and you can customize this through the puma.rb file. You may need to provision
the vm again with `vagrant provision` in order for this to takes effect in production
environment.
For further information about threads and workers in Puma, please take a look at
this great article by Heroku: [Puma web server article](https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server)

### Hacking hawk tools

Hawk's tools are the programs under the `hawk/tools` folder
(`hawk_chkpwd` and `hawk_invoke`). If you need to change something
on these files,  you need to provision the machine again with the command
`vagrant provision` to get this scripts compiled and copied to the correct
places, setuid-root and group to haclient in `/usr/bin` again. You should
end up with something like:

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

## Questions, Feedback, etc.

The upstream source repository can be found at
https://github.com/ClusterLabs/hawk . Issues, questions or pull
requests are welcome there.

Please direct comments, feedback, questions etc. to the Clusterlabs
users mailing list at http://clusterlabs.org/mailman/listinfo/users .

### Footnotes

<a name="footnote1">1</a>: https://github.com/ClusterLabs/booth/
