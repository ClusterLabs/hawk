//======================================================================
//                        HA Web Konsole (Hawk)
// --------------------------------------------------------------------
//            A web-based GUI for managing and monitoring the
//          Pacemaker High-Availability cluster resource manager
//
// Copyright (c) 2009-2011 Novell Inc., Tim Serong <tserong@novell.com>
//                        All Rights Reserved.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of version 2 of the GNU General Public License as
// published by the Free Software Foundation.
//
// This program is distributed in the hope that it would be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//
// Further, this software is distributed without any warranty that it is
// free of the rightful claim of any third person regarding infringement
// or the like.  Any license provided herein, whether implied or
// otherwise, applies only to this software file.  Patent licenses, if
// any, provided herein do not apply to combinations of this program with
// other software, or any other product whatsoever.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write the Free Software Foundation,
// Inc., 59 Temple Place - Suite 330, Boston MA 02111-1307, USA.
//
//======================================================================

/* Structure is:

   +-----------------------------------------+
   | +-[.node]-+ +-[.node]-+ +-[.inactive]-+ |
   | | [.rsrc] | | [.rsrc] | | [.rsrc      | |
   | | [.rsrc] | | [.rsrc] | | [.rsrc      | |
   | | [.rsrc] | | [.rsrc] | | [.rsrc      | |
   | +---------+ +---------+ +-------------+ |
   +-----------------------------------------+

Notion being nodes come and go by adding columns, resources come and
go by appending to each row.  So there's one HTML table with one row,
one column per node (plus one for the inactives).  Within each cell we
just add divs for resources.

That being said, we want clones and ms resources to appear on rows
by themselves, so you see all clone instances corresponding with each
other, and indeed can see that they are a clone.  So, instead, we have
one row for nodes, one row per clone/ms, and one remaining row which
all regular resources fall into.

*/
var table_view = {
  create: function() {
    var self = this;
    $("#content").prepend($('<div id="table" style="display: none;"><table cellpadding="0" cellspacing="0"><tbody></tbody></div>'));
    self.tbody = $("#table").find("tbody");
  },
  destroy: function() {
    // NYI
  },
  update: function() {
    var self = this;
    // Add/update nodes, then add/update resources
    $("#table").show();
    // Temporary shotgun:
    self.tbody.children().remove();
    self.tbody.append($('<tr class="nrow"></tr><tr></tr>'));
    var node_row = self.tbody.children(":first");
    var res_row = self.tbody.children(":last");
    $.each(cib.nodes, function() {
      // Switch cribbed from _cib_to_nodelist_panel()
      var className;
      var label = GETTEXT.node_state_unknown();
      switch (this.state) {
        case "online":
          className = "active";
          label = GETTEXT.node_state_online();
          break;
        case "offline":
          className = "inactive";
          label = GETTEXT.node_state_offline();
          break;
        case "pending":
          className = "transient";
          label = GETTEXT.node_state_pending();
          break;
        case "standby":
          className = "inactive";
          label = GETTEXT.node_state_standby();
          break;
        case "unclean":
          className = "error";
          label = GETTEXT.node_state_unclean();
          break;
      }
      var d = $(
        '<td class="ncol" id="ncol::' + this.uname + '"><div id="node::' + this.uname + '" class="ui-corner-all node ns-' + className + '">' +
            '<a id="node::' + this.uname + '::menu"><img src="' + url_root + '/images/transparent-16x16.gif" class="action-icon" alt="" /></a><span id="node::' + this.uname + '::label">' + escape_html(GETTEXT.node_state(this.uname, label)) + '</span>' +
        "</div></td>");
      node_row.append(d);
      res_row.append($('<td class="ncol"></td>'));
      if (!cib_file) {
        add_mgmt_menu($(jq("node::" + this.uname + "::menu")));
      }
    });
    
    // Inactive column
    // TODO(must): localize
    node_row.append($('<td style="text-align: center; vertical-align: middle; color: #888;">Inactive Resources</td>'));
    res_row.append($("<td></td>"));

    $.each(resources_by_id, function() {
      if (!this.instances) return;
      var res_id = this.id;
      $.each(this.instances, function(k) {
        var id = res_id;
        var is_clone_instance = false;
        if (k != "default") {
          id += ":" + k;
          is_clone_instance = true;
        }
        // Display logic same as _get_primitive()
        var node = null;
        var status_class = "res-primitive";
        var label = "";
        if (this.master) {
          label = GETTEXT.resource_state_master(id);
          node = this.master;
          status_class += " rs-active rs-master";
        } else if (this.slave) {
          label = GETTEXT.resource_state_slave(id);
          node = this.slave;
          status_class += " rs-active rs-slave";
        } else if (this.started) {
          label = GETTEXT.resource_state_started(id);
          node = this.started;
          status_class += " rs-active";
        } else if (this.pending) {
          label = GETTEXT.resource_state_pending(id);
          node = this.pending;
          status_class += " rs-transient";
        } else {
          label = GETTEXT.resource_state_stopped(id);
          status_class += " rs-inactive";
        }
        var d = $(
          '<div id="resource::' + id + '" class="ui-corner-all ' + status_class + '">' +
              '<a id="resource::' + id + '::menu"><img src="' + url_root + '/images/transparent-16x16.gif" class="action-icon" alt="" /></a><span id="resource::' + id + '::label">' + escape_html(label) + '</span>' +
          "</div>");
        var append_to = null;
        if (is_clone_instance) {
          if ($(jq("crow::" + res_id)).length == 0) {
            // TODO(must): localize
//            // TODO(must): will always say clone, even for ms
//            res_row.before($('<tr><td style="font-size: 80%;">' + GETTEXT.resource_clone(res_id) + "</td></tr>"));
            res_row.before($('<tr class="crow" id="crow::' + res_id + '"></tr>'));
            for (var i = 0; i < cib.nodes.length; i++) {
              $(jq("crow::" + res_id)).append($('<td class="ncol"></td>'));
            }
            $(jq("crow::" + res_id)).append($("<td></td>"));
          }
          append_to = $(jq("crow::" + res_id));
        } else {
          append_to = res_row;
        }
        if (node) {
          // CAN BE ON MULTIPLE NODES (*GAH*)
          $(append_to.children()[$(jq("ncol::" + node)).index()]).append(d);
        } else {
          append_to.children(":last").append(d);
        }
        if (!cib_file) {
          add_mgmt_menu($(jq("resource::" + id + "::menu")));
        }
      });
    });
  },
  hide: function() {
    var self = this;
    $("#table").hide();
    self.tbody.children().remove();
    $("#table").find(".ncol").remove();
  }
};

