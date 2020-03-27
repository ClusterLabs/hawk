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
  - [Features](doc/features.md)
  - [Build Dependencies](#build-dependencies)
    - [Dependencies](#dependencies)
  - [Installation](#installation)
    - [Installing The Easy Way](#installing-the-easy-way)
    - [Packaging Notes](#packaging-notes)
  - [A Note on SSL Certificates](#a-note-on-ssl-certificates)
  - [Hacking Hawk](#hacking-hawk)
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

![Status](/doc/screens/hawk_status.png)
![Wizard](/doc/screens/hawk_wizards.png)


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
