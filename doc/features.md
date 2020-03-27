# Features:

Note that this list of features is not complete, and is intended only
as a rough guide to the Hawk user interface.

    - [Resource Management](#resource-management)
    - [Multi-cluster Dashboard](#multi-cluster-dashboard)
    - [History Explorer](#history-explorer)
    - [Configuration](#configuration)
    - [Wizards](#wizards)
    - [View Configuration and Graph](#view-configuration-and-graph)
    - [Command Log](#command-log)
    - [Access Control Lists](#access-control-lists)
    - [Simulator](#simulator)

### Resource Management

From the status view of Hawk, you can control the state of individual
resources or resource groups, start / stop / promote / demote. You can
also migrate resources to and away from specific nodes, clean up
resources after failure and show a list of recent events for the
resource.

On the status page you can also manage nodes including setting node
attributes and displaying recent events related to the specific node.

Additionally, if there are any tickets configured (requires the use of
geo clustering via [booth](https://github.com/ClusterLabs/booth)
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

