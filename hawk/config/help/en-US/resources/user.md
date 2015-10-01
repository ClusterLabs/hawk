### ACL Target

Access control lists (ACLs) consist of an ordered set of access rules. Those can be combined into specific roles (for individual tasks like monitoring the cluster). Afterwards, assign users to a role that matches their tasks. 

- ACLs are an optional feature. 

- If ACLs are not enabled, `root` and all users of the `haclient` group have full read/write access to the cluster configuration.

- Even if ACLs are enabled and configured, both `root` and the default CRM owner `hacluster` always have full access to the cluster configuration.

#### Create User/ACL Target

**ACL Target ID**:  Define a unique ID.

**Roles**: Select one or multiple roles to assign to the user. 

