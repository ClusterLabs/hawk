### Promotable Resource

Promotable resources are a specialization of clones. They allow the
instances to be in one of two operating modes. When first starting up,
the resource is considered `promotable`. A subset of instances can
subsequently be `promoted`.

To create a promotable resource, define an ID and select the child
resource that you want to use for the promotable resource.

An example of a promotable resource is `ocf:linbit:drbd` for the
configuration of DRBD.
