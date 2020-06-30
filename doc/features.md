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


* [The Hawk Guide](http://hawk-guide.readthedocs.org/en/latest/)
* [SUSE Linux Enterprise High Availability Extension Documentation](http://www.suse.com/documentation/sle_ha/book_sleha/?page=/documentation/sle_ha/book_sleha/data/cha_ha_configuration_hawk.html)



## Features

Note that this list of features is not complete, and is intended only
as a rough guide to the Hawk user interface.

![Status](/screens/hawk_status.png)
![Wizard](/screens/hawk_wizards.png)


### Resource Management

From the status view of Hawk, you can control the state of individual
resources or resource groups, start / stop / promote / demote. You can
also migrate resources to and away from specific nodes, clean up
resources after failure and show a list of recent events for the
resource.

On the status page you can also manage nodes including setting node
attributes and displaying recent events related to the specific node.

Additionally, if there are any tickets configured (requires the use of
geo clustering via booth (https://github.com/ClusterLabs/booth/)

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
