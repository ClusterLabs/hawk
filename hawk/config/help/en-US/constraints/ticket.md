### Ticket

Tickets are a special type of constraint used for Geo clustering. A
ticket grants the right to run certain resources on a specific cluster
site.

To create a ticket constraint, specify a constraint ID, enter a
ticket's ID and add the resources that you want to depend on this
ticket. Additionally, you can set a loss-policy to define what should
happen to the resources if the ticket is revoked. The attribute
`loss-policy` can have the following values:

* `fence`: Fence the nodes that are running the relevant resources.
* `stop`: Stop the relevant resources.
* `freeze`: Do nothing to the relevant resources.
* `demote`: Demote relevant resources that are running in master mode to slave mode.

An example for a ticket constraint would be a primitive resource
`rsc1` that depends on `ticketA`. If you set `loss-policy="fence"`,
the node that runs `rsc1` would be fenced in case `ticketA` is
revoked from the cluster site this node belongs to.
