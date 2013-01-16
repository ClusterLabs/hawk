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
    $("#content").append($('<div id="table" style="display: none;"><table cellpadding="0" cellspacing="0"><tbody></tbody></div>'));
    self.tbody = $("#table").find("tbody");
    $(window).resize(self._fix_max_height);
  },
  destroy: function() {
    // NYI
  },
  update: function() {
    var self = this;
    // Add/update nodes, then add/update resources
    self._fix_max_height();
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
      var d = $('<td class="ncol" id="ncol::' + this.uname + '"></td>');
      d.append(new_item_div("node::" + this.uname));
      d.children(":first").attr("class", "ui-corner-all node ns-" + className);
      d.find("span").html(escape_html(GETTEXT.node_state(this.uname, label)));
      node_row.append(d);
      res_row.append($('<td class="ncol">&nbsp;</td>'));
      if (cib_source != "file") {
        add_mgmt_menu($(jq("node::" + this.uname + "::menu")));
      }
    });
    
    // Inactive column
    node_row.append($('<td style="text-align: center; vertical-align: middle; color: #888;">' + GETTEXT.inactive_heading() + "</td>"));
    res_row.append($("<td>&nbsp;</td>"));

    $.each(cib.resources, function() {
      var c = null;
      if (this.children) {
        if (this.type == "group") {
          $.each(this.children, function() {
            self._append_primitive(this, res_row);
          });
        } else if (this.type == "clone" || this.type == "master") {
          if (this.children.length != 1) return;  // can't happen
          var jq_crow_id = jq("crow::" + this.id);
          if ($(jq_crow_id).length == 0) {
            res_row.before($('<tr><td class="ncol" style="font-size: 80%;">' +
              (this.type == "clone" ? GETTEXT.resource_clone(this.id) : GETTEXT.resource_master(this.id)) + "</td></tr>"));
            res_row.before($('<tr class="crow" id="crow::' + this.id + '"></tr>'));
            for (var i = 0; i < cib.nodes.length; i++) {
              if (i > 0) $(jq_crow_id).prev().append($('<td class="ncol">&nbsp;</td>'));
              $(jq_crow_id).append($('<td class="ncol">&nbsp;</td>'));
            }
            $(jq_crow_id).prev().append($("<td>&nbsp;</td>"));
            $(jq_crow_id).append($("<td>&nbsp;</td>"));
          }
          var primitives = this.children[0].type == "group" ? this.children[0].children : this.children;
          $.each(primitives, function() {
            self._append_primitive(this, $(jq_crow_id));
          });
        }
      } else {
        self._append_primitive(this, res_row);
      }
    });
  },
  hide: function() {
    var self = this;
    $("#table").hide();
    self.tbody.children().remove();
    $("#table").find(".ncol").remove();
  },
  _fix_max_height: function() {
    var mh = $(window).height() - $("#content").position().top -
      parseInt($("#content").css("paddingTop")) -
      parseInt($("#content").css("paddingBottom")) -
      $("#view-switcher").height();
    $("#table").css("max-height", mh + "px");
  },
  // &nbsp; is inserted in empty cells so IE will render borders properly,
  // but we need to strip this before actually inserting DIVs, else we end up
  // with gaps in the display (*sigh*).
  _clean_cell: function(elem) {
    if (elem.children().length == 0) {
      elem.html("");
    }
  },
  _append_primitive: function(res, row) {
    var self = this;
    $.each(res.instances, function(k) {
      var id = res.id;
      var is_clone_instance = false;
      if (k != "default") {
        id += ":" + k;
        is_clone_instance = true;
      }
      // Display logic same as _get_primitive()
      var node = [];
      var status_class = "res-primitive";
      var label = "";
      if (this.master) {
        label = GETTEXT.resource_state_master(id);
        node = h2n(this.master);
        status_class += " rs-active rs-master";
      } else if (this.slave) {
        label = GETTEXT.resource_state_slave(id);
        node = h2n(this.slave);
        status_class += " rs-active rs-slave";
      } else if (this.started) {
        label = GETTEXT.resource_state_started(id);
        node = h2n(this.started);
        status_class += " rs-active";
      } else if (this.pending) {
        if (this.pending.length == 1 && this.pending[0].substate) {
          // Seriously, this'll always have a length of 1, but it never hurts to
          // be paranoid about these things.
          eval("label = GETTEXT.resource_state_" + this.pending[0].substate + "(id);");
        } else {
          label = GETTEXT.resource_state_pending(id);
        }
        node = h2n(this.pending);
        status_class += " rs-transient";
      } else {
        label = GETTEXT.resource_state_stopped(id);
        status_class += " rs-inactive";
      }
      var d = new_item_div("resource::" + id);
      d.attr("class", "ui-corner-all " + status_class);
      d.find("span").html(escape_html(label));
      if (node.length == 0) {
        self._clean_cell(row.children(":last"));
        row.children(":last").append(d);
      } else {
        self._clean_cell($(row.children()[$(jq("ncol::" + node[0])).index()]));
        $(row.children()[$(jq("ncol::" + node[0])).index()]).append(d);
        for (var i = 1; i < node.length; i++) {
          // Add multiply active instances, sans ID stuff
          self._clean_cell($(row.children()[$(jq("ncol::" + node[i])).index()]));
          $(row.children()[$(jq("ncol::" + node[i])).index()]).append($(
            '<div class="ui-corner-all ' + status_class + '">' +
              '<span>' + escape_html(label) + '</span>' +
            "</div>"));
        }
      }
      flag_error("resource::" + id, this.failed_ops);
      if (cib_source != "file") {
        add_mgmt_menu($(jq("resource::" + id + "::menu")));
      }
    });
  }
};

