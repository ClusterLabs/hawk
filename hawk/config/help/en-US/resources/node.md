### Node

Each node in the cluster will have an entry in the nodes section.

#### Name

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
