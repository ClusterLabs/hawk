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

  - [Overview](#overview)
  - [Features](doc/features.md)
  - [Dependencies](#dependencies)
  - [Installation](#installation)
  - [Packaging](#packaging)
  - [Hacking Hawk](#hacking-hawk)

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

### External links:

* [Website](http://hawk-ui.github.io)
* [The Hawk Guide](http://hawk-guide.readthedocs.org/en/latest/)
* [SUSE Linux Enterprise High Availability Extension Documentation](http://www.suse.com/documentation/sle_ha/book_sleha/?page=/documentation/sle_ha/book_sleha/data/cha_ha_configuration_hawk.html)
* [API Server Repository](https://github.com/ClusterLabs/hawk-apiserver)

![Status](/doc/screens/hawk_status.png)
![Wizard](/doc/screens/hawk_wizards.png)


## Dependencies:

The exact versions specified here may not be accurate. Also, note that
Hawk also requires the rubygems listed in `hawk/Gemfile`.

Build-deps:
 
* ruby >= 2.2
* pam-devel

Other deps:

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

#### Using Rpms

If you are running openSUSE Tumbleweed, you are in luck. All you have
to do is install the hawk2 package and then initialize the HA cluster:

```bash
zypper install hawk2
crm cluster init
```
Once initialized, go to `https://<IP>:7630/`.

### Deployment:

You can deploy hawk with https://github.com/SUSE/ha-sap-terraform-deployments.

If you want to deploy on containers have look at https://github.com/krig/docker-hawk


### Packaging Notes

* https://build.opensuse.org/package/show/network:ha-clustering:Factory/hawk2

Note that the `master` branch is used to build SLE15 version, and the other branches are per-os version.

## Hacking Hawk

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
