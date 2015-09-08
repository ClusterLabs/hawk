### Resource Template

If you need lots of resources with similar configurations, define a
resource template. After being defined, it can be referenced in
primitives or in certain types of constraints.

If a template is referenced in a primitive, the primitive inherits all
operations, instance attributes (parameters), meta attributes, and
utilization attributes defined in the template. Additionally, you can
define specific operations or attributes for your primitive. If any of
these are defined in both template and primitive, the values in the
primitive take precedence over the ones defined in the template.

To create a resource template, define an ID and specify some
parameters like class, (provider), and type -- exactly like you would
specify a primitive.
