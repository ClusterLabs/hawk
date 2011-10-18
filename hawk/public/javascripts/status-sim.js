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
    var self = this;
    $("#container").append($(
      '<div id="simulator" style="display: none; font-size: 80%;">' +
        '<form onsubmit="return false;"><table style="width: 100%;">' +
          "<tr>" +
            "<th>" + escape_html(GETTEXT.sim_injected()) + "</th>" +
          "</tr>" +
          "<tr>" +
            '<td><select id="sim-injections" multiple="multiple" size="4" style="width: 100%;"><option></option></select></td>' +
            '<td style="padding-left: 1em;">' +
              '<button id="sim-run" type="button" style="min-width: 6em;" disabled="disabled">' + escape_html(GETTEXT.sim_run()) + '</button> ' +
            "</td>" +
            '<td style="padding-left: 1em;">' +
              '<a class="disabled" id="sim-get-info" target="hawk-sim-info">' + escape_html(GETTEXT.sim_details()) + '</a><br/>' +
              '<a class="disabled" id="sim-get-in" target="hawk-sim-info">' + escape_html(GETTEXT.sim_cib_in()) + '</a><br/>' +
              '<a class="disabled" id="sim-get-out" target="hawk-sim-info">' + escape_html(GETTEXT.sim_cib_out()) + '</a><br/>' +
              '<a class="disabled" id="sim-get-graph" target="hawk-sim-info">' + escape_html(GETTEXT.sim_graph()) + '</a>' +
              ' <a class="disabled" id="sim-get-graph-xml" target="hawk-sim-info">(xml)</a>' +
            "</td>" +
          "</tr>" +
          "<tr>" +
            "<td>" +
              '<button id="sim-inject-node" type="button" style="min-width: 6em;">' + escape_html(GETTEXT.sim_inject_node()) + '</button> ' +
              '<button id="sim-inject-op" type="button" style="min-width: 6em;">' + escape_html(GETTEXT.sim_inject_op()) + '</button> ' +
              '<button id="sim-inject-del" type="button"> - </button> ' +
            "</td>" +
          "</tr>" +
        "</table></form>" +
      "</div>"));

    $("#sim-inject-node").click(function() {
      var html = '<form onsubmit="return false;"><table><tr>' +
        '<th>' + escape_html(GETTEXT.sim_node_node()) + '</th><td><select id="inject-node-uname">';
      $.each(cib.nodes, function() {
        html += '<option value="' + this.uname + '">' + this.uname + "</option>\n";
      });
      html += '</select></td><td>&nbsp;</td><th>' + escape_html(GETTEXT.sim_node_state()) + '</th><td><select id="inject-node-state">' +
          '<option value="online">' + escape_html(GETTEXT.node_state_online()) + '</option>' +
          '<option value="offline">' + escape_html(GETTEXT.node_state_offline()) + '</option>' +
          '<option value="unclean">' + escape_html(GETTEXT.node_state_unclean()) + '</option>' +
          "</select></td>" +
        "</tr></table></form>";
      $("#dialog").html(html);
      var b = {}
      b[GETTEXT.ok()] = function() {
        var s = "node " + $("#inject-node-uname").val() + " " + $("#inject-node-state").val();
        $("#sim-injections").append($('<option title="' + s + '" value="' + s + '">' + s + "</option>"));
        $("#sim-run").removeAttr("disabled");
        $(this).dialog("close");
      };
      b[GETTEXT.cancel()] = function() {
        $(this).dialog("close");
      };
      $("#dialog").dialog("option", {
        title:    escape_html(GETTEXT.sim_node_inject()),
        buttons:  b
      });
      $("#dialog").dialog("open");
    });

    $("#sim-inject-op").click(function() {
      var html = '<form onsubmit="return false;"><table>';

      html += '<tr><td>' + escape_html(GETTEXT.sim_op_resource()) + '</td><td><select id="inject-op-resource">';
      $.each(resources_by_id, function() {
        if (!this.instances) return;
        var id = this.id;
        $.each(this.instances, function(k) {
          var iid = id + (k == "default" ? "" : ":" + k);
          html += '<option value="' + iid + '">' + iid + "</option>\n";
        });
      });
      html += "</select></td></tr>";

      html += '<tr><th>' + escape_html(GETTEXT.sim_op_operation()) + '</th><td><select id="inject-op-operation">' +
          '<option value="monitor">monitor</option>' +
          '<option value="start">start</option>' +
          '<option value="stop">stop</option>' +
          '<option value="promote">promote</option>' +
          '<option value="demote">demote</option>' +
          '<option value="notify">notify</option>' +
          '<option value="migrate_to">migrate_to</option>' +
          '<option value="migrate_from">migrate_from</option>' +
          "</select></td></tr><tr>";

      html += '<th>' + escape_html(GETTEXT.sim_op_interval()) + '</th>' +
          '<td><input type="text" size="10" id="inject-op-interval"/> (ms)</td></tr>';

      html += '<tr><th>' + escape_html(GETTEXT.sim_node_node()) + '</th><td><select id="inject-op-node">';
      $.each(cib.nodes, function() {
        html += '<option value="' + this.uname + '">' + this.uname + "</option>\n";
      });
      html += "</tr>";

      html += '<tr><th>' + escape_html(GETTEXT.sim_op_result()) + '</th><td><select id="inject-op-result">' +
          '<option value="success">' + escape_html(GETTEXT.sim_result_success()) + '</option>' +
          '<option value="unknown">' + escape_html(GETTEXT.sim_result_unknown()) + '</option>' +
          '<option value="args">' + escape_html(GETTEXT.sim_result_args()) + '</option>' +
          '<option value="unimplemented">' + escape_html(GETTEXT.sim_result_unimplemented()) + '</option>' +
          '<option value="perm">' + escape_html(GETTEXT.sim_result_perm()) + '</option>' +
          '<option value="installed">' + escape_html(GETTEXT.sim_result_installed()) + '</option>' +
          '<option value="configured">' + escape_html(GETTEXT.sim_result_configured()) + '</option>' +
          '<option value="not_running">' + escape_html(GETTEXT.sim_result_not_running()) + '</option>' +
          '<option value="master">' + escape_html(GETTEXT.sim_result_master()) + '</option>' +
          '<option value="failed_master">' + escape_html(GETTEXT.sim_result_failed_master()) + '</option>' +
          "</select></td></tr>";

      html += "</table></form>";
      $("#dialog").html(html);

      // Set sensible defaults for whatever resource we're fiddling with
      self._inject_op_set_res_defaults();
      $("#inject-op-resource").change(self._inject_op_set_res_defaults);

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
        title:    escape_html(GETTEXT.sim_op_inject()),
        buttons:  b
      });
      $("#dialog").dialog("open");
    });

    // TODO(should): disable if nothing selected
    $("#sim-inject-del").click(function() {
      $.each($("#sim-injections").val() || [], function() {
        $("#sim-injections").children("option[value='" + this.toString() + "']").remove();
      });
      if (!$("#sim-injections").children().length) {
        $("#sim-run").attr("disabled", "disabled");
      }
    });

    $("#sim-run").click(function() {
      $("#simulator").dialog("option", "title", escape_html(GETTEXT.sim_busy()));
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
        $("#simulator").dialog("option", "title", escape_html(GETTEXT.sim_final()));
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
    var self = this;
    var b = {};
    b[GETTEXT.reset()] = function() {
      self._reset();
    },
    b[GETTEXT.close()] = function() {
      $(this).dialog("close");
    };
    $("#simulator").dialog("option", {
      title:    escape_html(GETTEXT.sim_init()),
      buttons:  b,
      close:    function() {
        $(document.body).removeClass("sim");
        $("#errorbar").hide(); // forcibly hide error bar when deactivating simulator
        hide_status();
        $("#onload-spinner").show();
        cib_source = "live";
        update_cib();
      }
    });
    $("#errorbar").hide(); // forcibly hide error bar when activating simulator
    hide_status();
    $("#onload-spinner").show();
    self._reset(function() {
      $(document.body).addClass("sim");
      $("#simulator").dialog("open");
    });
  },
  _reset: function(callback) {
    $("#simulator").dialog("option", "title", escape_html(GETTEXT.sim_busy()));
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
      if (callback) {
        callback();
      }
      $("#simulator").dialog("option", "title", escape_html(GETTEXT.sim_init()));
    });
  },
  _inject_op_set_res_defaults: function() {
    var id_parts = $("#inject-op-resource").val().split(":");
    var instance = resources_by_id[id_parts[0]].instances[id_parts.length == 2 ? id_parts[1] : "default"];
    // TODO(should): Can this be reused elsewhere? (cf: panel_view::_get_primitive)
    var running_on = instance.master || instance.slave || instance.started || instance.pending;
    if (running_on) {
      $("#inject-op-node").val(running_on[0]);
    }
  }
};
