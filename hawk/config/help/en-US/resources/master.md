<h2>Multi-state</h2>
<p>Multi-state resources are a specialization of clones. They allow the
instances to be in one of two operating modes (called
<code>active/passive</code>, <code>primary/secondary</code>, or <code>master/slave</code>).</p>
<p>To create a multi-state resource, define an ID and select the child
resource that you want to use for the multi-state resource.</p>
<p>An example of a multi-state resource is <code>ocf:linbit:drbd</code> for the
configuration of DRBD.</p>
