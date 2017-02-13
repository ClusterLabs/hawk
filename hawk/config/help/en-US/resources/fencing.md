### Fencing Topology

Configuring a fencing topology enables different fencing methods for
different nodes, as well as allowing the use of multiple fencing
methods for any particular node.

Example uses of topologies:

* Try poison-pill and fail back to power.
* Try disk and network, and fall back to power if either fails.
* Initiate a kdump, then poweroff the node.

#### Level

The fencing topology consists of a series of levels,
each with a target, an index and a list of devices.

The operation is finished when a level has passed (success), or all
levels have been attempted (failed).

If the operation failed, the next step is determined by the Policy
Engine and/or crmd.

#### Target

The target can be

* The name of a single node to which this level applies,
* A regular expression matching the names of nodes to which this level applies,
* A node attribute which is set (to the target value) for nodes to which this level applies.

#### Index

The order in which to attempt the levels.
Levels are attempted in ascending order until one succeeds.
Valid values are 1 through 9.

If a device fails, processing terminates for the current level. No
further devices in that level are exercised, and the next level is
attempted instead.

#### Devices

A comma-separated list of devices that must all be tried for this level.

If the operation succeeds for all the listed devices in a level, the
level is deemed to have passed.
