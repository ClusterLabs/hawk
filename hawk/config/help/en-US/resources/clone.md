## Clone

Clones are resources that can run simultaneously on multiple nodes in
your cluster.

To create a clone, define an ID and select the child resource that you
want to use as clone. Any regular resources or resource groups can be
cloned. Instances of cloned resources may behave identically. However,
they may also be configured differently, depending on which node they
are hosted.

An example of a resource that can be configured as clone is
`ocf:pacemaker:controld` for cluster file systems like OCFS2.
