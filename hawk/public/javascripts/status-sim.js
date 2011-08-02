//======================================================================
//                        HA Web Konsole (Hawk)
// --------------------------------------------------------------------
//            A web-based GUI for managing and monitoring the
//          Pacemaker High-Availability cluster resource manager
//
// Copyright (c) 2011 Novell Inc., All Rights Reserved.
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

var simulator = {
  create: function() {
    $("#container").append($(
      '<div id="simulator" style="display: none; font-size: 80%;">' +
        "<form><table>" +
          "<tr>" +
            // TODO(must): Localize, likewise button and link labels
            "<th>Injected State:</th>" +
          "</tr>" +
          "<tr>" +
            '<td><select id="sim-injections" multiple="multiple" size="4" style="width: 15em;"><option></option></select></td>' +
            '<td style="padding-left: 1em;">' +
              '<button id="sim-run" type="button" style="min-width: 6em;" disabled="disabled">Run &gt;</button> ' +
            "</td>" +
            '<td style="padding-left: 1em;">' +
              '<a class="disabled" id="sim-get-info" target="hawk-sim-info">Details</a><br/>' +
              '<a class="disabled" id="sim-get-in" target="hawk-sim-info">CIB (in)</a><br/>' +
              '<a class="disabled" id="sim-get-out" target="hawk-sim-info">CIB (out)</a><br/>' +
              '<a class="disabled" id="sim-get-graph" target="hawk-sim-info">Graph</a>' +
              ' <a class="disabled" id="sim-get-graph-xml" target="hawk-sim-info">(xml)</a>' +
            "</td>" +
          "</tr>" +
          "<tr>" +
            "<td>" +
              '<button id="sim-inject-node" type="button" style="min-width: 6em;">+ Node</button> ' +
              '<button id="sim-inject-op" type="button" style="min-width: 6em;">+ Op</button> ' +
              '<button id="sim-inject-del" type="button"> - </button> ' +
            "</td>" +
          "</tr>" +
        "</table></form>" +
      "</div>"));

    $("#sim-inject-node").click(function() {
      var html = "<form><table><tr>" +
        // TODO(must): localize form labels etc.
        '<th>Node:</th><td><select id="inject-node-uname">';
      $.each(cib.nodes, function() {
        html += '<option value="' + this.uname + '">' + this.uname + "</option>\n";
      });
      html += '</select></td><td>&nbsp;</td><th>State:</th><td><select id="inject-node-state">' +
          '<option value="online">Online</option>' +
          '<option value="offline">Offline</option>' +
          '<option value="unclean">Unclean</option>' +
          "</select></td>" +
        "</tr></table></form>";
      $("#dialog").html(html);
      var b = {}
      b[GETTEXT.ok()] = function() {
        $("#sim-injections").append($("<option>node " + $("#inject-node-uname").val() + " " + $("#inject-node-state").val() + "</option>"));
        $("#sim-run").removeAttr("disabled");
        $(this).dialog("close");
      };
      b[GETTEXT.cancel()] = function() {
        $(this).dialog("close");
      };
      $("#dialog").dialog("option", {
        // TODO(must): Localize title
        title:    "Inject Node State",
        buttons:  b
      });
      $("#dialog").dialog("open");
    });

    $("#sim-inject-op").click(function() {
      // TODO(must): localize form labels etc.
      var html = "<form><table>";

      html += '<tr><th>Operation:</th><td><select id="inject-op-operation">' +
          '<option value="monitor">Monitor</option>' +
          '<option value="start">Start</option>' +
          '<option value="stop">Stop</option>' +
          '<option value="promote">Promote</option>' +
          '<option value="demote">Demote</option>' +
          '<option value="notify">Notify</option>' +
          '<option value="migrate_to">Migrate To</option>' +
          '<option value="migrate_from">Migrate From</option>' +
          "</select></td></tr><tr>";

      html += '<th>Interval:</th>' +
          '<td><input type="text" size="10" id="inject-op-interval"/> (ms)</td></tr>';

      html += '<tr><th>Resource:</td><td><select id="inject-op-resource">';
      $.each(resources_by_id, function() {
        if (!this.instances) return;
        var id = this.id;
        $.each(this.instances, function(k) {
          var iid = id + (k == "default" ? "" : ":" + k);
          html += '<option value="' + iid + '">' + iid + "</option>\n";
        });
      });
      html += "</select></td></tr>";

      html += '<tr><th>Result:</th><td><select id="inject-op-result">' +
          '<option value="success">Success</option>' +
          '<option value="err_generic">Generic Error</option>' +
          '<option value="err_args">Wrong Argument(s)</option>' +
          '<option value="err_unimplemented">Not Implemented</option>' +
          '<option value="err_perm">Permission Denied</option>' +
          '<option value="err_installed">Not Installed</option>' +
          '<option value="err_configured">Not Configured</option>' +
          '<option value="not_running">Not Running</option>' +
          '<option value="running_master">Running Master</option>' +
          '<option value="failed_master">Failed Master</option>' +
          "</select></td></tr>";

      html += '<tr><th>Node:</th><td><select id="inject-op-node">';
      $.each(cib.nodes, function() {
        html += '<option value="' + this.uname + '">' + this.uname + "</option>\n";
      });
      html += "</tr>";

      html += "</table></form>";
      $("#dialog").html(html);
      var b = {}
      b[GETTEXT.ok()] = function() {
        var interval = parseInt($("#inject-op-interval").val());
        if (isNaN(interval)) interval = 0;
        var s = "op " +
          $("#inject-op-operation").val() + ":" + interval + " " +
          $("#inject-op-resource").val() + " " +
          $("#inject-op-result").val() + " " +
          $("#inject-op-node").val();
        $("#sim-injections").append($('<option title="' + s + '" value="' + s + '">' + s + "</option>"));
        $("#sim-run").removeAttr("disabled");
        $(this).dialog("close");
      };
      b[GETTEXT.cancel()] = function() {
        $(this).dialog("close");
      };
      $("#dialog").dialog("option", {
        // TODO(must): Localize title
        title:    "Inject Operation",
        buttons:  b
      });
      $("#dialog").dialog("open");
    });

    // TODO(should): disable if nothing selected
    $("#sim-inject-del").click(function() {
      $.each($("#sim-injections").val() || [], function() {
        $("#sim-injections").children("option[value='" + this.toString() + "']").remove();
      });
      if (!$("#sim-injections").val()) {
        $("#sim-run").attr("disabled", "disabled");
      }
    });

    $("#sim-run").click(function() {
      // TODO(must): Spinner
      var i = [];
      $("#sim-injections").children().each(function() {
        i.push($(this).val());
      });
      $.post(url_root + "/main/sim_run", { "injections[]": i }, function() {
        cib_source = "sim:out";
        update_cib();
        $("#sim-get-info").removeClass("disabled").attr("href", url_root + "/main/sim_get?file=info");
        $("#sim-get-in").removeClass("disabled").attr("href", url_root + "/main/sim_get?file=in");
        $("#sim-get-out").removeClass("disabled").attr("href", url_root + "/main/sim_get?file=out");
        $("#sim-get-graph").removeClass("disabled").attr("href", url_root + "/main/sim_get?file=graph");
        $("#sim-get-graph-xml").removeClass("disabled").attr("href", url_root + "/main/sim_get?file=graph&format=xml");
      });
      return false;
    });

    $("#simulator").dialog({
      resizable:      true,
      position:       ["right", "bottom"],
      width:          "30em",
      draggable:      true,
      modal:          false,
      autoOpen:       false,
      closeOnEscape:  false
    });
  },
  activate: function() {
    var b = {};
    b[GETTEXT.reset()] = function () {
      $("#sim-get-info").addClass("disabled").removeAttr("href");
      $("#sim-get-in").addClass("disabled").removeAttr("href");
      $("#sim-get-out").addClass("disabled").removeAttr("href");
      $("#sim-get-graph").addClass("disabled").removeAttr("href");
      $("#sim-get-graph-xml").addClass("disabled").removeAttr("href");
      $("#sim-run").attr("disabled", "disabled");
      $("#sim-injections").children().remove();
      $.get(url_root + "/main/sim_reset", function() {
        // TODO(must): spinner in dialog
        cib_source = "sim:in";
        update_cib();
      });
    },
    b[GETTEXT.close()] = function() {
      $(document.body).removeClass("sim");
      $(this).dialog("close");
      hide_status();
      $("#onload-spinner").show();
      cib_source = "live";
      update_cib();
    };
    $("#simulator").dialog("option", {
      title:    "Simulator",
      buttons:  b
    });
    hide_status();
    $("#onload-spinner").show();
    // TODO(should): pretty much a dupe of above reset function; consolidate
    $("#sim-get-info").addClass("disabled").removeAttr("href");
    $("#sim-get-in").addClass("disabled").removeAttr("href");
    $("#sim-get-out").addClass("disabled").removeAttr("href");
    $("#sim-get-graph").addClass("disabled").removeAttr("href");
    $("#sim-get-graph-xml").addClass("disabled").removeAttr("href");
    $("#sim-run").attr("disabled", "disabled");
    $("#sim-injections").children().remove();
    $.get(url_root + "/main/sim_reset", function() {
      cib_source = "sim:in";
      update_cib();
      $(document.body).addClass("sim");
      $("#simulator").dialog("open");
    });
  }
};
