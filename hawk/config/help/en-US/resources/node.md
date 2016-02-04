### Node

Each node in the cluster will have an entry in the nodes section.

The name of a node may be different from the node ID. The name is
taken from one of these locations:

1. The value stored in `corosync.conf` under `ring0_addr` in the `nodelist`, if it does not contain an IP address
2. The value stored in `corosync.conf` under `name` in the `nodelist`
3. The value of `uname -n`

#### Attributes

Node attributes are a special type of option that applies to a node.

Beyond the basic definition of a node, the administrator can describe
the node’s attributes, such as how much RAM, disk, what OS or kernel
version it has, perhaps even its physical location. This information
can then be used by the cluster when deciding where to place
resources.

#### Utilization

To configure the capacity a node provides and the resource’s
requirements, use utilization attributes. You can name the utilization
attributes according to your preferences and define as many name/value
pairs as your configuration needs. However, the attribute’s values
must be integers.
