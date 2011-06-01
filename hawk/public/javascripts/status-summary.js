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

var summary_view = {
  create: function() {
    // Summary needs to show:
    // stonith enabled
    // no quorum policy
    // symmetric
    // stickiness(?)
    // maintenance mode
    $("#content").prepend($(
      '<div id="summary" style="display: none;">' +
        '<h1>Summary</h1>' +
        '<div id="nodesum"><span id="nodesum-label"></span>' +
          "<table>" +
            '<tr id="nodesum-pending"><td>' + GETTEXT.node_state_pending() + ":</td><td></td></tr>" +
            '<tr id="nodesum-online"><td>' + GETTEXT.node_state_online() + ":</td><td></td></tr>" +
            '<tr id="nodesum-standby"><td>' + GETTEXT.node_state_standby() + ":</td><td></td></tr>" +
            '<tr id="nodesum-offline"><td>' + GETTEXT.node_state_offline() + ":</td><td></td></tr>" +
            '<tr id="nodesum-unclean"><td>' + GETTEXT.node_state_unclean() + ":</td><td></td></tr>" +
          "</table>" +
        "</div>" +
        '<div id="ressum"><span id="ressum-label"></span>' +
          "<table>" +
            // TODO(must): Localize
            '<tr id="ressum-pending"><td>Pending:</td><td></td></tr>' +
            '<tr id="ressum-started"><td>Started:</td><td></td></tr>' +
            '<tr id="ressum-master"><td>Master:</td><td></td></tr>' +
            '<tr id="ressum-slave"><td>Slave:</td><td></td></tr>' +
            '<tr id="ressum-stopped"><td>Stopped:</td><td></td></tr>' +
          "</table>" +
        "</div>" +
        '<div id="errorsum">' +
        "</div>" +
      "</div>"));
    $("#summary").find("tr").hide();
  },
  destroy: function() {
    // NYI
  },
  update: function() {
    var self = this;

    $("#summary").show();

    $("#nodesum-label").html(escape_html(GETTEXT.nodes_configured(cib.nodes.length)));
    self._zero_counters("#nodesum");
    $.each(cib.nodes, function() {
      self._increment_counter("#nodesum-" + this.state);
    });
    self._show_counters("#nodesum");

    $("#ressum-label").html(escape_html(GETTEXT.resources_configured(resource_count)));
    self._zero_counters("#ressum");
    $.each(resources_by_id, function() {
      if (!this.instances) return;
      $.each(this.instances, function() {
        if (this.master) {
          self._increment_counter("#ressum-master");
        } else if (this.slave) {
          self._increment_counter("#ressum-slave");
        } else if (this.started) {
          self._increment_counter("#ressum-started");
        } else if (this.pending) {
          self._increment_counter("#ressum-pending");
        } else {
          self._increment_counter("#ressum-stopped");
        }
      });
    });
    self._show_counters("#ressum");
  },
  hide: function() {
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

