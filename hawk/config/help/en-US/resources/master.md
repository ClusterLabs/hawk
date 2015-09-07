## Multi-state

Multi-state resources are a specialization of clones. They allow the
instances to be in one of two operating modes (called
`active/passive`, `primary/secondary`, or `master/slave`).

To create a multi-state resource, define an ID and select the child
resource that you want to use for the multi-state resource.

An example of a multi-state resource is `ocf:linbit:drbd` for the
configuration of DRBD.
