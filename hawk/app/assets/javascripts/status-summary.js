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

var summary_view = {
  active_detail: null,
  create: function() {
    var self = this;
    // Summary needs to show:
    // stonith enabled
    // no quorum policy
    // symmetric
    // stickiness(?)
    // maintenance mode
    $("#content").append($(
      '<div id="summary" style="display: none;" class="ui-corner-all">' +
        "<h1>" + GETTEXT.summary() + "</h1>" +
        '<div id="confsum" class="summary">' +
          '<h2><span id="confsum-label">' + GETTEXT.cluster_config() + "</span></h2>" +
          '<table cellpadding="0" cellspacing="0" style="white-space: nowrap;">' +
            '<tr id="confsum-stonith-enabled"><td>' + GETTEXT.stonith_enabled() + ":</td><td></td></tr>" +
            '<tr id="confsum-no-quorum-policy"><td>' + GETTEXT.no_quorum_policy() + ":</td><td></td></tr>" +
            '<tr id="confsum-symmetric-cluster"><td>' + GETTEXT.symmetric_cluster() + ":</td><td></td></tr>" +
            '<tr id="confsum-default-resource-stickiness"><td>' + GETTEXT.resource_stickiness() + ":</td><td></td></tr>" +
            '<tr id="confsum-maintenance-mode"><td>' + GETTEXT.maintenance_mode() + ":</td><td></td></tr>" +
          "</table>" +
        "</div>" +
        '<div id="ticketsum" class="summary" style="display: none;">' +
          '<h2 class="clickable">' + GETTEXT.tickets() + '</h2>' +
          '<table cellpadding="0" cellspacing="0" style="white-space: nowrap;">' +
            '<tr id="ticketsum-granted" class="rs-active clickable"><td><span style="float: left;" class="ui-icon ui-icon-check"></span>' + GETTEXT.ticket_granted() + ':</td><td class="ar"></td></tr>' +
            '<tr id="ticketsum-elsewhere" class="rs-transient clickable"><td><span style="float: left;" class="ui-icon ui-icon-cancel"></span>' + GETTEXT.ticket_elsewhere() + ':</td><td class="ar"></td></tr>' +
            '<tr id="ticketsum-revoked" class="rs-inactive clickable"><td><span style="float: left;" class="ui-icon ui-icon-cancel"></span>' + GETTEXT.ticket_revoked() + ':</td><td class="ar"></td></tr>' +
          '</table>' +
        '</div>' +
        '<div id="nodesum" class="summary">' +
          '<h2 class="clickable" id="nodesum-label"></h2>' +
          '<table cellpadding="0" cellspacing="0">' +
            '<tr id="nodesum-pending" class="ns-transient clickable"><td><span style="float: left;" class="ui-icon ui-icon-refresh"></span>' + GETTEXT.node_state_pending() + ':</td><td class="ar"></td></tr>' +
            '<tr id="nodesum-online" class="ns-active clickable"><td><span style="float: left;" class="ui-icon ui-icon-play"></span>' + GETTEXT.node_state_online() + ':</td><td class="ar"></td></tr>' +
            '<tr id="nodesum-standby" class="ns-inactive clickable"><td><span style="float: left;" class="ui-icon ui-icon-pause"></span>' + GETTEXT.node_state_standby() + ':</td><td class="ar"></td></tr>' +
            '<tr id="nodesum-offline" class="ns-inactive clickable"><td><span style="float: left;" class="ui-icon ui-icon-stop"></span>' + GETTEXT.node_state_offline() + ':</td><td class="ar"></td></tr>' +
            '<tr id="nodesum-unclean" class="ns-error clickable"><td><span style="float: left;" class="ui-icon ui-icon-notice"></span>' + GETTEXT.node_state_unclean() + ':</td><td class="ar"></td></tr>' +
          "</table>" +
        "</div>" +
        '<div id="ressum" class="summary">' +
          '<h2 class="clickable" id="ressum-label"></span></h2>' +
          '<table cellpadding="0" cellspacing="0">' +
            '<tr id="ressum-pending" class="rs-transient clickable"><td><span style="float: left;" class="ui-icon ui-icon-refresh"></span>' + GETTEXT.resource_state_pending() + ':</td><td class="ar"></td></tr>' +
            '<tr id="ressum-started" class="rs-active clickable"><td><span style="float: left;" class="ui-icon ui-icon-play"></span>' + GETTEXT.resource_state_started() + ':</td><td class="ar"></td></tr>' +
            '<tr id="ressum-failed" class="rs-error clickable"><td><span style="float: left;" class="ui-icon ui-icon-notice"></span>' + GETTEXT.resource_state_failed() + ':</td><td class="ar"></td></tr>' +
            '<tr id="ressum-master" class="rs-master clickable"><td><span style="float: left;" class="ui-icon ui-icon-play"></span>' + GETTEXT.resource_state_master() + ':</td><td class="ar"></td></tr>' +
            '<tr id="ressum-slave" class="rs-slave clickable"><td><span style="float: left;" class="ui-icon ui-icon-play"></span>' + GETTEXT.resource_state_slave() + ':</td><td class="ar"></td></tr>' +
            '<tr id="ressum-stopped" class="rs-inactive clickable"><td><span style="float: left;" class="ui-icon ui-icon-stop"></span>' + GETTEXT.resource_state_stopped() + ':</td><td class="ar"></td></tr>' +
          "</table>" +
        "</div>" +
      "</div>" +
      '<div id="details" style="display: none;" class="ui-corner-all">' +
        '<div style="float: right;"><button type="button" style="border: none; background: none; font-size: 0.7em; margin-right: -0.5em;">' +
          GETTEXT.close() + "</button></div><h1>" + GETTEXT.details() + "</h1>" +
        '<div id="itemlist"></div>' +
      "</div>"));
    $("#summary").find("tr").each(function() {
      $(this).hide();
      if ($(this).hasClass("clickable")) {
        $(this).css("textDecoration", "underline");
        $(this).click(function() {
          self.active_detail = $(this).attr("id");
          $("#itemlist").children().hide();
          $("#itemlist").children("." + self.active_detail).show();
          $("#details").show();
        });
      }
    });
    $("#summary").find("h2").each(function() {
      if ($(this).hasClass("clickable")) {
        $(this).css("textDecoration", "underline");
        $(this).click(function() {
          self.active_detail = $(this).parent().attr("id");
          $("#itemlist").children().hide();
          $("#itemlist").children("." + self.active_detail).show();
          $("#details").show();
        });
      }
    });
    $("#details").find("button").button({
      text: false,
      icons: {
        primary: "ui-icon-close"
      }
    }).click(function() {
        $("#details").hide();
        self.active_detail = null;
    });
  },
  destroy: function() {
    // NYI
  },
  update: function() {
    var self = this;

    $("#summary").show();
    $.each(["stonith-enabled", "no-quorum-policy", "symmetric-cluster",
            "default-resource-stickiness", "maintenance-mode"], function() {
      var p = this.toString();
      if (cib.crm_config[p] != null) {
        $("#confsum-" + p).show().children(":last").html(escape_html(cib.crm_config[p].toString()));
      } else {
        $("#confsum-" + p).hide();
      }
    });
    // Special case so rsc_defaults stickiness overrides display of crm_config default-resource-stickiness
    if (cib.rsc_defaults["resource-stickiness"] != null && cib.rsc_defaults["resource-stickiness"] != "default") {
      $("#confsum-default-resource-stickiness").show().children(":last").html(escape_html(cib.rsc_defaults["resource-stickiness"].toString()));
    }
    // Special case for important highlights
    if (cib.crm_config["stonith-enabled"]) {
      $("#confsum-stonith-enabled").removeClass("rs-error");
    } else {
      $("#confsum-stonith-enabled").addClass("rs-error");
    }
    if (cib.crm_config["maintenance-mode"]) {
      $("#confsum-maintenance-mode").addClass("rs-transient");
    } else {
      $("#confsum-maintenance-mode").removeClass("rs-transient");
    }

    // Rebuild item list each time
    $("#itemlist").children().remove();

    if ($.isEmptyObject(cib.tickets)) {
      $("#ticketsum").hide();
    } else {
      $("#ticketsum").show();
      self._zero_counters("#ticketsum");
      // this loop is (mostly) duplicated in status-panel.js
      $.each(cib.tickets, function(id) {
        // Mild "abuse" of res-* style classes and GETTEXT.node_state
        var status_class = "res-primitive";
        var label;
        var state_icon;
        if (this.granted) {
          self._increment_counter("#ticketsum-granted");
          status_class += " rs-active ticketsum ticketsum-granted";
          label = GETTEXT.node_state(id, GETTEXT.ticket_granted(this.standby));
          state_icon = "ui-icon-check";
        } else if (this.leader && this.leader.toLowerCase() != "none") {
          self._increment_counter("#ticketsum-elsewhere");
          status_class += " rs-transient ticketsum ticketsum-elsewhere";
          label = GETTEXT.node_state(id, GETTEXT.ticket_elsewhere(this.standby));
          state_icon = "ui-icon-cancel";
        } else {
          self._increment_counter("#ticketsum-revoked");
          status_class += " rs-inactive ticketsum ticketsum-revoked";
          label = GETTEXT.node_state(id, GETTEXT.ticket_revoked(this.standby));
          state_icon = "ui-icon-cancel";
        }
        var display = "none";
        if (self.active_detail && status_class.indexOf(self.active_detail) >= 0) {
          display = "auto";
        }
        var d = new_item_div("ticket::" + id);
        d.attr("class", "ui-corner-all " + status_class).attr("style", "display: " + display);
        d.find("span").html(label);
        $("#itemlist").append(d);
        var ti = [];
        if (this["last-granted"]) {
          ti.push(GETTEXT.ticket_last_granted(date_string(new Date(this["last-granted"] * 1000))));
        }
        if (this["leader"]) {
          ti.push(GETTEXT.ticket_leader(this["leader"]));
        }
        if (this["expires"]) {
          ti.push(GETTEXT.ticket_expires(this["expires"]));
        }
        if (ti.length) {
          flag_info("ticket::" + id, ti.join("\n"));
        }
        if (cib_source != "file" && cib.booth && cib.booth.me) {
          add_mgmt_menu($(jq("ticket::" + id + "::menu")));
        }
        $(jq("ticket::" + id + "::state")).removeClass();
        if (state_icon) {
          $(jq("ticket::" + id + "::state")).addClass("ui-icon " + state_icon);
        }
      });
      self._show_counters("#ticketsum");
    }


    $("#nodesum-label").html(escape_html(cib.nodes_label));
    self._zero_counters("#nodesum");
    $.each(cib.nodes, function() {
      self._increment_counter("#nodesum-" + this.state);
      // Switch cribbed from _cib_to_nodelist_panel()
      var className;
      var label = GETTEXT.node_state_unknown();
      var state_icon;
      switch (this.state) {
        case "online":
          className = "active nodesum nodesum-online";
          label = GETTEXT.node_state_online();
          state_icon = "ui-icon-play";
          break;
        case "offline":
          className = "inactive nodesum nodesum-offline";
          label = GETTEXT.node_state_offline();
          state_icon = "ui-icon-stop";
          break;
        case "pending":
          className = "transient nodesum nodesum-pending";
          label = GETTEXT.node_state_pending();
          state_icon = "ui-icon-refresh";
          break;
        case "standby":
          className = "inactive nodesum nodesum-standby";
          label = GETTEXT.node_state_standby();
          state_icon = "ui-icon-pause";
          break;
        case "unclean":
          className = "error nodesum nodesum-unclean";
          label = GETTEXT.node_state_unclean();
          state_icon = "ui-icon-notice";
          break;
      }
      var display = 'none';
      if (self.active_detail && className.indexOf(self.active_detail) >= 0) {
        display = "auto";
      }
      var d = new_item_div("node::" + this.uname);
      d.attr("class", "ui-corner-all node ns-" + className).attr("style", "display: " + display);
      d.find("span").html(escape_html(GETTEXT.node_state(this.uname, label)));
      $("#itemlist").append(d);
      flag_maintenance("node::" + this.uname, this.maintenance ? GETTEXT.maintenance_mode() : false);
      if (cib_source != "file") {
        add_mgmt_menu($(jq("node::" + this.uname + "::menu")));
      }
      $(jq("node::" + this.uname + "::state")).removeClass();
      if (state_icon) {
        $(jq("node::" + this.uname + "::state")).addClass("ui-icon " + state_icon);
      }
    });
    self._show_counters("#nodesum");

    $("#ressum-label").html(escape_html(cib.resources_label));
    self._zero_counters("#ressum");
    $.each(resources_by_id, function() {
      if (!this.instances) return;
      var res = this;
      var res_id = this.id;
      $.each(this.instances, function(k) {
        var id = res_id;
        if (k != "default") {
          id += ":" + k;
        }
        // Display logic same as _get_primitive()
        var status_class = "res-primitive";
        var label = "";
        if (this.master) {
          self._increment_counter("#ressum-master");
          label = GETTEXT.resource_state_master(id, h2n(this.master));
          status_class += " rs-active rs-master ressum ressum-master";
          state_icon = "ui-icon-play";
        } else if (this.slave) {
          self._increment_counter("#ressum-slave");
          label = GETTEXT.resource_state_slave(id, h2n(this.slave));
          status_class += " rs-active rs-slave ressum ressum-slave";
          state_icon = "ui-icon-play";
        } else if (this.started) {
          self._increment_counter("#ressum-started");
          label = GETTEXT.resource_state_started(id, h2n(this.started));
          status_class += " rs-active ressum ressum-started";
          state_icon = "ui-icon-play";
        } else if (this.failed) {
          self._increment_counter("#ressum-failed");
          label = GETTEXT.resource_state_failed(id, h2n(this.failed));
          status_class += " rs-error ressum ressum-failed";
          state_icon = "ui-icon-notice";
        } else if (this.pending) {
          if (this.pending.length == 1 && this.pending[0].substate) {
            // Seriously, this'll always have a length of 1, but it never hurts to
            // be paranoid about these things.
            eval("label = GETTEXT.resource_state_" + this.pending[0].substate + "(id, this.pending[0].node);");
          } else {
            label = GETTEXT.resource_state_pending(id, h2n(this.pending));
          }
          self._increment_counter("#ressum-pending");
          status_class += " rs-transient ressum ressum-pending";
          state_icon = "ui-icon-refresh";
        } else {
          self._increment_counter("#ressum-stopped");
          label = GETTEXT.resource_state_stopped(id);
          status_class += " rs-inactive ressum ressum-stopped";
          state_icon = "ui-icon-stop";
        }
        var display = 'none';
        if (self.active_detail && status_class.indexOf(self.active_detail) >= 0) {
          display = "auto";
        }
        var d = new_item_div("resource::" + id, cpt(res));
        d.attr("class", "ui-corner-all " + status_class).attr("style", "display: " + display);
        d.find("span").html(escape_html(label));
        $("#itemlist").append(d);
        flag_error("resource::" + id, this.failed_ops);
        flag_maintenance("resource::" + id, this.is_managed ? false : GETTEXT.unmanaged());
        if (cib_source != "file") {
          add_mgmt_menu($(jq("resource::" + id + "::menu")));
        }
        $(jq("resource::" + id + "::state")).removeClass();
        if (state_icon) {
          $(jq("resource::" + id + "::state")).addClass("ui-icon " + state_icon);
        }
      });
    });
    self._show_counters("#ressum");

    // Hide item list if there's nothing to show
    if ($("#itemlist").children(":visible").length == 0) {
      $("#details").hide();
      self.active_detail = null;
    }
  },
  hide: function() {
    $("#summary").hide();
    $("#details").hide();
    $("#itemlist").children().remove();
    this.active_detail = null;
  },
  _zero_counters: function(parent_id) {
    $(parent_id).children("table").find("tr").each(function() {
      $(this).children(":last").text("0");
    });
  },
  _increment_counter: function(row_id) {
    $(row_id).children(":last").text(parseInt($(row_id).children(":last").text()) + 1);
  },
  _show_counters: function(parent_id) {
    $(parent_id).children("table").find("tr").each(function() {
      if (parseInt($(this).children(":last").text())) {
        $(this).show();
      } else {
        $(this).hide();
      }
    });
  }
};

