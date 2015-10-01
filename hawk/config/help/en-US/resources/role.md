### ACL Role

An ACL role is a set of rules which describe access rights to CIB. Each rule consists of:

- an access right `(read`, `write`, or `deny`)
- a specification (XPath expression, type, or ID reference) where to apply the rule 

#### Create Role
 
**Role ID**: Define a unique ID. 

**Right**: Select the access right (read/write/deny).

**Xpath**: Enter an Xpath expression for the CIB elements that you want the access right to apply to (e.g. `//constraints/rsc_location` to make it apply to location constraints).

**Type**: Enter the name of the CIB XML element that you want the access right to apply to (e.g. `rsc_location` to make it apply to location constraints).

**Ref**: Enter the ID of the CIB XML element that you want the access right to apply to type (e.g. `rsc1` to make it apply to all XML elements with the ID `rsc1`).
