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

var cib = null;
var resources_by_id = null;
var resource_count = 0;

var cib_file = false;
var update_period = 0;

var current_view = null;

function jq(id)
{
  return "#" + id.replace(/(:|\.)/g,'\\$1');
}

function update_errors(errors)
{
  $("#errorbar").html("");
  if (errors.length) {
    $("#errorbar").show();
    $.each(errors, function() {
      $("#errorbar").append($('<div class="error">' + escape_html(this.toString()) + '</div>'));
    });
  } else {
    $("#errorbar").hide();
  }
}

// Like string.split, but breaks on "::"
// TODO(could): think about changing our naming conventions so we don't need this.
function dc_split(str)
{
  parts = new Array();
  var s = 0;
  for (;;) {
    var e = str.indexOf("::", s);
    if (e == -1)
    {
      parts.push(str.substr(s));
      break;
    }
    parts.push(str.substr(s, e - s));
    s = e + 2;
  }
  return parts;
}

// When given an element ID in the form "type::id(:n)", return "id"
// (suitable for extracting node and resource IDs, minus clone instance if any)
function item_id(str)
{
  return dc_split(str)[1].split(":")[0];
}

// title: dialog title
// id:    node or resource id
// type:  either "node" or "resource"
// op:    op to perform
function confirm_op(title, id, type, op)
{
  $("#dialog").html(GETTEXT[type + "_" + op](id));
  // TODO(could): Is there a neater construct for this localized button thing?
  var b = {};
  b[GETTEXT.yes()]  = function() { perform_op(type, id, op); $(this).dialog("close"); };
  b[GETTEXT.no()]   = function() { $(this).dialog("close"); }
  $("#dialog").dialog("option", {
    title:    title,
    buttons:  b
  });
  $("#dialog").dialog("open");
}

function perform_op(type, id, op, extra)
{
  var state = "neutral";
  var c = $(jq(type + "::" + id));
  if (c.hasClass("ns-active"))        state = "active";
  else if(c.hasClass("ns-inactive"))  state = "inactive";
  else if(c.hasClass("ns-error"))     state = "error";
  else if(c.hasClass("ns-transient")) state = "transient";
  else if(c.hasClass("rs-active"))    state = "active";
  else if(c.hasClass("rs-inactive"))  state = "inactive";
  else if(c.hasClass("rs-error"))     state = "error";
  $(jq(type + "::" + id + "::menu")).children(":first").attr("src", url_root + "/images/spinner-16x16-" + state + ".gif");

  $.ajax({ url: url_root + "/main/" + type + "/" + op,
    data: "format=json&" + type + "=" + id + (extra ? "&" + extra : ""),
    type: "POST",
    success: function() {
      // Remove spinner (a spinner that stops too early is marginally better than one that never stops)
      $(jq(type + "::" + id + "::menu")).children(":first").attr("src", url_root + "/images/icons/properties.png");
    },
    error: function(request) {
      // Remove spinner
      $(jq(type + "::" + id + "::menu")).children(":first").attr("src", url_root + "/images/icons/properties.png");
      var json = json_from_request(request);
      if (json) {
        error_dialog(json.error, json.stderr ? json.stderr : null);
      } else {
        if (request.status == 403) {
          // 403 == permission denied
          error_dialog(GETTEXT.err_denied());
        } else {
          error_dialog(GETTEXT.err_unexpected(request.status));
        }
      }
    }
  });
}

function add_mgmt_menu(e)
{
  e.addClass("clickable");
  e.children(":first").attr("src", url_root + "/images/icons/properties.png");
  // parts[0] is "node" or "resource", parts[1] is node or resource ID
  var parts = dc_split(e.attr("id"));
  if (parts[0] == "node") {
    e.click(function() {
      return $(jq("menu::node")).popupmenu("popup", $(this));
    });
  } else {
    var id_parts = parts[1].split(":");
    var is_clone_instance = id_parts.length == 2
    if (id_parts.length == 2) {
      // It's a clone instance, hide everything except Edit and Delete
      e.click(function() {
        return $(jq("menu::resource")).popupmenu("popup", $(this), [0, 1, 2, 3, 4, 5, 6, 7]);
      });
    } else {
      if (resources_by_id[id_parts[0]].toplevel) {
        // Top-level item, thus migratable
        if (resources_by_id[id_parts[0]].children && resources_by_id[id_parts[0]].type == "master") {
          // Paranoid check for has children + type == "master" (else one day someone
          // will make an RA called "master", and we'd think it was a primitive).
          e.click(function() {
            return $(jq("menu::resource")).popupmenu("popup", $(this));
          });
        } else {
          // Top-level, non-MS.
          e.click(function() {
            return $(jq("menu::resource")).popupmenu("popup", $(this), [4, 5]);
          });
        }
      } else {
        // It's a child and not migratable
        e.click(function() {
          return $(jq("menu::resource")).popupmenu("popup", $(this), [2, 3, 4, 5]);
        });
      }
    }
  }
}

function do_update(cur_epoch)
{
  // No refresh if this is a static test
  if (cib_file) return;

  $.ajax({ url: url_root + "/monitor?" + cur_epoch,
    type: "GET",
    success: function(data) {
      if (data) {
        if (data.epoch != cur_epoch) {
          update_cib();
        } else {
          do_update(data.epoch);
        }
      } else {
        // This can occur when onSuccess is called erroneously
        // on network failure; re-request in 15 seconds
        // TODO(should): this was originally observed when using Prototype,
        // is it still a problem with jQuery?  If no, this can be deleted
        // (but may need "new_epoch = data ? data.epoch : '';" above
        // instead of direct use of data.epoch).
        setTimeout("do_update('" + cur_epoch + "')", 15000);
      }
    },
    error: function() {
      // Busted, retry in 15 seconds.
      setTimeout("do_update('" + cur_epoch + "')", 15000);
    }
  });
}

function update_resources_by_id(resources)
{
  var toplevel = false;
  if (!resources) {
    resources_by_id = {};
    resources = cib.resources;
    toplevel = true;
    resource_count = 0;
  }
  $.each(resources, function() {
    resources_by_id[this.id] = this;
    resources_by_id[this.id].toplevel = toplevel;
    if (this.children) {
      update_resources_by_id(this.children);
    }
    if (this.instances) {
      $.each(this.instances, function() {
        resource_count++;
      });
    }
  });
}

function hide_status()
{
  $("#dc_current").hide();
  $("#dc_version").hide();
  $("#dc_stack").hide();

  current_view.hide();
}

function update_cib()
{
  $.ajax({ url: url_root + "/cib/" + (cib_file ? cib_file : "live"),
    data: "format=json" + (cib_file ? "&debug=file" : ""),
    type: "GET",
    success: function(data) {
      $("#onload-spinner").hide();
      if (data) {   // When is it possible for this to not be set?
        cib = data;
        update_resources_by_id();
        update_errors(cib.errors);
        if (cib.meta) {
          $("#dc_current").html(GETTEXT.dc_current(cib.meta.dc)).show();
          var dc_version = cib.crm_config["dc-version"].match(/.*-[a-f0-9]{12}/);
          if (!dc_version) dc_version = cib.crm_config["dc-version"];
          $("#dc_version").html(GETTEXT.dc_version(dc_version.toString())).show();
          $("#dc_stack").html(GETTEXT.dc_stack(cib.crm_config["cluster-infrastructure"])).show();

          current_view.update();
        } else {
          // TODO(must): is it possible to get here with empty cib.errors?
          hide_status();
        }
      }
      if (update_period) {
        // Handy when debugging...
        setTimeout(update_cib, update_period);
      } else {
        do_update(cib.meta ? cib.meta.epoch : "");
      }
    },
    error: function(request) {
      if (request.status == 403) {
        // 403 == permission denied, boot the user out
        window.location.replace(url_root + "/logout?reason=forbidden");
      } else {
        var json = json_from_request(request);
        if (json && json.errors) {
          // Sane response (server not dead, but actual error, e.g.:
          // access denied):
          update_errors(json.errors);
        } else {
          // Unexpectedly busted (e.g.: server fried):
          update_errors([GETTEXT.err_unexpected(request.status + " " + request.statusText)]);
        }
        hide_status();
        if (cib_file) {
          $("#onload-spinner").hide();
        } else {
          // Try again in 15 seconds.  No need for roundtrip through
          // the monitor function in this case (it'll just hammer the
          // server unnecessarily)
          setTimeout(update_cib, 15000);
        }
      }
    }
  });
}

function change_view(new_view) {
  if (current_view == new_view) return;
  current_view.hide();
  current_view = new_view;
  current_view.update();
}

function hawk_init()
{
  var q = $.parseQuery();
  if (q.cib_file) {
    cib_file = q.cib_file;
  }
  if (q.update_period) {
    update_period = isNaN(q.update_period) ? 0 : parseInt(q.update_period) * 1000;
  }

  summary_view.create();
  panel_view.create();
  table_view.create();

  $("#content").prepend($(
    '<div id="view-switcher" style="float: right;"><form>' +
      // TODO(must): Localize
      '<input id="view-summary" name="view-radio" type="radio" checked="checked" /><label for="view-summary">Summary View</label>' +
      '<input id="view-panel" name="view-radio" type="radio" /><label for="view-panel">Tree View</label>' +
      //'<input id="view-table" name="view-radio" type="radio" /><label for="view-table">Table View</label>' +
    "</form></div"));
  $("#view-switcher").buttonset();
  $("#view-summary").button("option", { icons: { primary: "icon-view-summary" }, text: false }).click(function() {
    change_view(summary_view);
  });
  $("#view-panel").button("option", { icons: { primary: "icon-view-panel" }, text: false }).click(function() {
    change_view(panel_view);
  });
  //$("#view-table").button("option", { icons: { primary: "icon-view-table" }, text: false }).click(function() {
  //  change_view(table_view);
  //});

  // Default to summary view (need this in init, not raw, else we're dependent
  // on status-summary.js being included before status.js)
  current_view = summary_view;

  update_cib();
}
