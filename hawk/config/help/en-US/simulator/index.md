### Batch Mode

Using Batch Mode, it is possible to stage changes to the cluster and
apply them as a single transaction, instead of having each change take
effect immediately.

For example, Batch Mode can be used when creating groups of resources
that depend on each other, or to avoid intermediate incomplete
configurations being applied to the cluster.

* Apply multiple changes to the cluster as a single operation.

* Simulate changes and cluster events.

### Simulator

While Batch Mode is enabled, the *cluster simulator* runs
automatically after every change. The expected outcome of the change
is reflected in the user interface.

When stopping a resource while in Batch Mode, the resource is not
actually stopped. However, the user interface will update showing the
resource as stopped, since the change is simulated.

The simulator will process all cluster configuration changes,
including creating and removing resources, changing resource
parameters or editing constraints.

It is also possible to *simulate events* in the cluster. This
includes nodes going online or offline, resource operations and
tickets being granted or revoked.

#### Controls

To see more details about the simulation results, open the **Show**
dialog from the Batch Mode control panel, at the top of the
screen.

The batched changes can be applied to the cluster configuration as a
single operation using the **Apply** button in the Batch Mode
control panel. To discard the changes and disable Batch Mode, use the
**Discard** button.

#### Wizards

Note that wizards that perform actions beyond simple cluster
configuration will perform those actions on the live system, not
simply as simulated changes. Take care when using wizards while in
Batch Mode.

