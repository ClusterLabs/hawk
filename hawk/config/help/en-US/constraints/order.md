### Order

Ordering constraints define the order in which resources are started
and stopped.

To create an order constraint, specify an ID, select the resources
between which to define the constraint, and add a score. The score
determines the location relationship between the resources: The
constraint is mandatory if the score is greater than zero, otherwise
it is only a suggestion. The default value is INFINITY. Keeping the
option `Symmetrical` set to `Yes` (default) defines that the resources
are stopped in reverse order.

An example for use of an order constraint is a Web service
(e.g. Apache) that depends on a certain IP address. Configure
resources for the IP address and the Web service, then add an order
constraint that defines that the IP address is started before Apache
is started.
