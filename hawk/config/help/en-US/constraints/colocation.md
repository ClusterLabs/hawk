### Colocation

A colocational constraint tells the cluster which resources may or may not run
together on a node.

To create a location constraint, specify an ID, select the resources between
which to define the constraint, and add a kind. The kind determines the
location relationship between the resources.

* Positive values: The resources should run on the same node.
* Negative values: The resources should not run on the same node.
* Kind of INFINITY: The resources have to run on the same node.
* Kind of -INFINITY: The resources must not run on the same node.

An example for use of a colocation constraint is a Web service that depends on
an IP address. Configure individual resources for the IP address and the Web
service, then add a colocation constraint with a kind of INFINITY. It defines
that the Web service must run on the same node as the IP address. This also
means that if the IP address is not running on any node, the Web service will
not be permitted to run.
