# TODO

* Show constraints for resource:

  Parse output of `crm_resource --resource <rsc> -A`

* Controls for all resources: stop all, start all, ... ?

* Display allocation scores and blocked status

* Show if a resource has failcounts

* Better timeline control for history explorer

Show time of events, details for events in preview

* Optimize history explorer

This needs work in crmsh to cache metadata for report between calls

* Better graph display

Render graphs client-side, enable interactive / zooming graphs

* cibsecret support

* Create a pacemaker rubygem written in C which interfaces directly
with pacemaker?

* A better solution for live tracking; websockets maybe?

* Replace popen3, safe_x, invoker etc. as much as possible with
  David Majda's command.rb

* Better error handling - link to action in error message

* Move logfiles to /var/log/hawk (or rely on journald / syslog here?)

* Better validation everywhere

* Dashboard doesn't take url_root into account

* Batch mode: Better handling of initial state

* Wizards: Branching wizards

* Wizards: Better validation

* Ability to clean up deleted / orphaned resources

* Show migration constraints

* Show constraints that apply to a resource

* Show quorum status (warn if not quorate)

* Improved constraint editing

  - Basic / Advanced for more constraint types
  - More intuitive resource set editor

* Create cloned / ms resource directly (checkbox in primitive creation
"make clone / ms" ?)

