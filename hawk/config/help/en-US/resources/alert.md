### Alert

Alerts may be configured to take some external action when a cluster
event occurs (node failure, resource starting or stopping, etc.).

As with resource agents, the cluster calls an external program (an
alert agent) to handle alerts. The cluster passes information about
the event to the agent via environment variables. Agents can do
anything desired with this information (send an e-mail, log to a file,
update a monitoring system, etc.).

Multiple alert agents may be configured; the cluster will call all of
them for each event.

Alert agents will be called only on cluster nodes. They will be called
for events involving Pacemaker Remote nodes, but they will never be
called on those nodes.

#### Recipients

Usually alerts are directed towards a recipient. Thus each alert may
be additionally configured with one or more recipients. The cluster
will call the agent separately for each recipient.

The recipient may be anything the alert agent can recognize — an IP
address, an e-mail address, a file name, whatever the particular agent
supports.

#### Instance Attributes

Agent-specific configuration values may be configured as instance
attributes. These will be passed to the agent as additional
environment variables. The number, names and allowed values of these
instance attributes are completely up to the particular agent.

#### Meta Attributes

Meta-attributes can be configured for alert agents to affect how
Pacemaker calls them.
