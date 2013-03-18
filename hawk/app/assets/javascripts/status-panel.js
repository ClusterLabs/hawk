//======================================================================
//                        HA Web Konsole (Hawk)
// --------------------------------------------------------------------
//            A web-based GUI for managing and monitoring the
//          Pacemaker High-Availability cluster resource manager
//
// Copyright (c) 2009-2013 SUSE LLC, All Rights Reserved.
//
// Author: Tim Serong <tserong@suse.com>
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

var panel_view = {
  create: function() {
    $("#content").append($(
//      '<div id="filter" style="display: none; width: 100%;">' +
//        '<input type="checkbox" id="show-active" checked="checked"/> Show Active&nbsp;&nbsp;' +
//        '<input type="checkbox" id="show-inactive" checked="checked"/> Show Inactive' +
//      "</div>" +
      '<div id="config" style="display: none;"></div>' +
      '<div id="nodereslist" style="display: none;">' +
        '<div id="nodelist"></div>' +
        '<div id="reslist"></div>' +
      "</div>"));
    $("#config").panel({
      menu_icon: url_root + "/assets/transparent-16x16.gif",
      label:     GETTEXT.cluster_config(),
      body:      $('<table id="config::props" style="padding: 0.25em 0.5em;"></table>')
    });
    $("#nodelist").panel({
      menu_icon: url_root + "/assets/transparent-16x16.gif"
    });
    $("#reslist").panel({
      menu_icon: url_root + "/assets/transparent-16x16.gif"
    });
/*    
    // Filter problems:
    // - visibility not applied to new resources or resources that
    //   change state (say you're showing active and not stopped, and
    //   an active resource stops - it'll still be visible in the new
    //   stopped state)
    // - panel headings still show expanded even though there's nothing
    //   inside.  need to add something like:
    //   - " 3 active resources/nodes hidden"
    //   - " 3 inactive resources/nodes hidden"
    $("#show-active").click(function() {
      if (this.checked) {
        $(".rs-active").show();
        $(".ns-active").show();
      } else {
        $(".rs-active").hide();
        $(".ns-active").hide();
      }
    });
    $("#show-inactive").click(function() {
      if (this.checked) {
        $(".rs-inactive").show();
        $(".ns-inactive").show();
      } else {
        $(".rs-inactive").hide();
        $(".ns-inactive").hide();
      }
    });
*/    
  },
  destroy: function() {
    // NYI
  },
  update: function() {
    var self = this;
    $("#config").show();
//    $("#filter").show();
    var props = [];
    for (var e in cib.crm_config) {
      if (e == "cluster-infrastructure" ||
          e == "dc-version" ||
          e == "last-lrm-refresh") {
        // TODO(should): This is a bit rough - consolidate with crm_config editor props
        continue;
      }
      props.push(e);
    }
    props.sort();
    var rows = $("<tbody/>");
    for (var i = 0; i < props.length; i++) {
      rows.append("<tr><th>" + props[i] + "</td><td>" + escape_html(cib.crm_config[props[i]].toString()) + "</td></tr>");
    }
    $(jq("config::props")).children().remove();
    $(jq("config::props")).append(rows);

    $("#nodereslist").show();

    if (self._update_panel(self._cib_to_nodelist_panel(cib.nodes, cib.nodes_label))) {
      $("#nodelist").panel("expand");
    }

    if (self._update_panel(self._cib_to_reslist_panel(cib.resources, cib.resources_label))) {
      $("#reslist").panel("expand");
    }
  },
  hide: function() {
    $("#config").hide();
    $("#nodereslist").hide();
    // Need to remove nodes and resources, because we're reusing the IDs in
    // summary_view.  Unfortunate side-effect is that the panel view reverts
    // to whatever the default expansion state would be when you switch views,
    // rather than remaining how the user had expanded things.
    $("#nodelist").panel("body_element").children().remove();
    $("#reslist").panel("body_element").children().remove();
//    $("#filter").hide();
  },
  // need to pass parent in with open flag (e.g.: nodelist, reslist)
  _update_panel: function(panel) {
    var self = this;
    if ($(jq(panel.id)).data("panel")) {
      // "Real" ui.panel expandable panel
      $(jq(panel.id)).panel("set_class", panel.className);
      $(jq(panel.id)).panel("set_label", panel.label);
      if (panel.id.indexOf("resource") == 0) {
        flag_maintenance(panel.id, panel.is_managed ? false : GETTEXT.unmanaged());
      }
    } else {
      // Individual (non-ui.panel) resources/nodes
      $(jq(panel.id)).attr("class", "ui-corner-all " + panel.className);
      $(jq(panel.id+"::label")).html(panel.label);
      $(jq(panel.id+"::state")).removeClass();
      if (panel.state_icon) {
        $(jq(panel.id+"::state")).addClass("ui-icon " + panel.state_icon);
      }
      flag_error(panel.id, panel.error ? panel.error : []);
      if (panel.id.indexOf("resource") == 0) {
        flag_maintenance(panel.id, panel.is_managed ? false : GETTEXT.unmanaged());
      } else {
        flag_maintenance(panel.id, panel.maintenance ? GETTEXT.maintenance_mode() : false);
      }
    }

    if (!panel.children) return false;

    var expand = panel.open ? true : false;   // do we really need to be this obscure?
    var b = $(jq(panel.id)).panel("body_element");
    var c = b.children(":first");
    $.each(panel.children, function() {
      if (!c.length || c.attr("id") != this.id) {
        var d;
        if ($(jq(this.id)).length) {
          // already got one for this resource, tear it out and reuse it.
          d = $(jq(this.id)).detach();
        } else {
          // brand spanking new
          if (this.children) {
            d = $('<div id="' + this.id + '"/>');
            d.panel({
              menu_icon: url_root + "/assets/transparent-16x16.gif",
              menu_id:   this.id + "::menu",
              error_id:  this.id + "::error",
              open:      this.open
            });
          } else {
            d = new_item_div(this.id);
          }
        }
        if (!c.length) {
          b.append(d);
        } else {
          c.before(d);
        }
        if (cib_source != "file") {
          // Only add menus when running on mutable CIB
          add_mgmt_menu($(jq(this.id + "::menu")));
        }
      } else {
        c = c.next();
      }
      if (self._update_panel(this)) {
        $(jq(panel.id)).panel("expand");
        expand = true;
      }
    });
    // If there's any child nodes left, get rid of 'em
    while (c.length) {
      var nc = c.next();
      c.remove();
      c = nc;
    }
    return expand;
  },
  _cib_to_nodelist_panel: function(nodes, label) {
    var panel = {
      id:         "nodelist",
      className:  "",
      style:      "",
      label:      label,
      open:       false,
      children:   []
    };
    $.each(nodes, function() {
      var className;
      var state_icon;
      var label = GETTEXT.node_state_unknown();
      switch (this.state) {
        case "online":
          className = "active";
          label = GETTEXT.node_state_online();
          state_icon = "ui-icon-play";
          break;
        case "offline":
          className = "inactive";
          label = GETTEXT.node_state_offline();
          state_icon = "ui-icon-stop";
          break;
        case "pending":
          className = "transient";
          label = GETTEXT.node_state_pending();
          state_icon = "ui-icon-refresh";
          break;
        case "standby":
          className = "inactive";
          label = GETTEXT.node_state_standby();
          state_icon = "ui-icon-pause";
          break;
        case "unclean":
          className = "error";
          label = GETTEXT.node_state_unclean();
          state_icon = "ui-icon-notice";
          break;
        default:
          // This can't happen
          className = "error";
          break;
      }
      if (this.state != "online") {
        panel.open = true;
      }
      panel.children.push({
        id:         "node::" + this.uname,
        className:  "node ns-" + className,
        label:      GETTEXT.node_state(this.uname, label),
        state_icon: state_icon,
        menu:       true,
        maintenance: this.maintenance
      });
    });
    return panel;
  },
  // TODO(must): sort order for injected instances might be wrong
  _get_primitive: function(res) {
    var set = [];
    for (var i in res.instances) {
      var id = res.id;
      if (i != "default") id += ":" + i;
      var status_class = "res-primitive";
      var label;
      var active = false;
      var state_icon;
      if (res.instances[i].master) {
        label = GETTEXT.resource_state_master(id, h2n(res.instances[i].master));
        status_class += " rs-active rs-master";
        state_icon = "ui-icon-play";
        active = true;
      } else if (res.instances[i].slave) {
        label = GETTEXT.resource_state_slave(id, h2n(res.instances[i].slave));
        status_class += " rs-active rs-slave";
        state_icon = "ui-icon-play";
        active = true;
      } else if (res.instances[i].started) {
        label = GETTEXT.resource_state_started(id, h2n(res.instances[i].started));
        status_class += " rs-active";
        state_icon = "ui-icon-play";
        active = true;
      } else if (res.instances[i].pending) {
        if (res.instances[i].pending.length == 1 && res.instances[i].pending[0].substate) {
          // Seriously, this'll always have a length of 1, but it never hurts to
          // be paranoid about these things.
          eval("label = GETTEXT.resource_state_" + res.instances[i].pending[0].substate + "(id, res.instances[i].pending[0].node);");
        } else {
          label = GETTEXT.resource_state_pending(id, h2n(res.instances[i].pending));
        }
        status_class += " rs-transient";
        state_icon = "ui-icon-refresh";
      } else {
        label = GETTEXT.resource_state_stopped(id);
        status_class += " rs-inactive";
        state_icon = "ui-icon-stop";
      }
      set.push({
        id:         "resource::" + id,
        instance:   i,
        className:  status_class,
        label:      label,
        state_icon: state_icon,
        active:     active,
        error:      res.instances[i].failed_ops,
        is_managed: res.instances[i].is_managed
      });
    }
    return set;
  },
  _get_group: function(res) {
    var self = this;
    var instances = [];
    var groups = {};
    $.each(res.children, function() {
      $.each(self._get_primitive(this), function() {
        if (!groups[this.instance]) {
          instances.push(this.instance);
          groups[this.instance] = {
            id:        "resource::" + res.id,
            className: "res-group rs-active",
            label:     GETTEXT.resource_group(res.id),
            open:      false,
            children:  [],
            is_managed: res.is_managed
          };
          if (this.instance != "default") {
            groups[this.instance].id += ":" + this.instance;
            groups[this.instance].label += ":" + this.instance;
          }
        }
        if (!this.active) {
          groups[this.instance].open = true;
          groups[this.instance].className = "res-group rs-inactive";
        }
        groups[this.instance].children.push(this);
      });
    });
    set = []
    $.each(instances.sort(), function() {
      set.push(groups[this]);
    });
    return set;
  },
  _get_clone: function(res) {
    var self = this;
    var status_class = "rs-active";
    var children = [];
    var open = false;
    $.each(res.children, function() {
      if (this.type == "group") {
        $.each(self._get_group(this), function() {
          if (this.open) open = true;
          if (this.className.indexOf("rs-active") == -1) status_class = "rs-inactive";
          children.push(this);
        });
      } else {
        $.each(self._get_primitive(this), function() {
          if (!this.active) {
            open = true;
            status_class = "rs-inactive";
          }
          children.push(this);
        });
      }
    });
    if (res.type == "master") {
      status_class += " res-ms";
    }
    return {
      id:         "resource::" + res.id,
      className:  "res-clone " + status_class,
      label:      (res.type == "master" ? GETTEXT.resource_master(res.id) : GETTEXT.resource_clone(res.id)),
      open:       open,
      children:   children,
      is_managed: res.is_managed
    };
  },
  _cib_to_reslist_panel: function(resources, label) {
    var self = this;
    var panel = {
      id:         "reslist",
      className:  "",
      style:      "",
      label:      label,
      open:       false,
      children:   []
    };
    $.each(resources, function() {
      var c = null;
      if (this.children) {
        if (this.type == "group") {
          c = self._get_group(this)[0];
          if (c.open) panel.open = true;
        } else if (this.type == "clone" || this.type == "master") {
          c = self._get_clone(this);
          if (c.open) panel.open = true;
        }
      } else {
        c = self._get_primitive(this)[0];
        if (!c.active) panel.open = true;
      }
      if (c) {
        panel.children.push(c);
      }
    });
    return panel;
  }
};
