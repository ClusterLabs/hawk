<h2>Clone</h2>
<p>Clones are resources that can run simultaneously on multiple nodes in
your cluster.</p>
<p>To create a clone, define an ID and select the child resource that you
want to use as clone. Any regular resources or resource groups can be
cloned. Instances of cloned resources may behave identically. However,
they may also be configured differently, depending on which node they
are hosted.</p>
<p>An example of a resource that can be configured as clone is
<code>ocf:pacemaker:controld</code> for cluster file systems like OCFS2.</p>
