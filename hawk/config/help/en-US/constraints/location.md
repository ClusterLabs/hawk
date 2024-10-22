### Location

A location constraint defines on which node a resource may be run, is
preferred to be run, or may not be run.

To create a location constraint, specify an ID, select the resource
for which to define the constraint, a kind and node. The kind
indicates the value you are assigning to this resource
constraint. Constraints with higher kinds are applied before those
with lower kinds.

An example of a location constraint is to place all resources related
to a certain database on the same node.
