// Copyright (c) 2009-2013 Tim Serong <tserong@suse.com>
// See COPYING for license.

var cib = null;
var resources_by_id = null;

var cib_file = "";
var cib_source = "live";
// Force periodic refresh when running on test server
var update_period = window.location.port == 3000 ? 15000 : 0;

var update_req = null;

var current_view = null;

function h2n(a) {
  var n = [];
  $.each(a, function(i, h) {
    n.push(h.node);
  });
  return n;
}

function update_errors(errors)
{
  if (errors.length) {
    var html;
    html = '<ul>';
    for (var i = 0; i < errors.length; i++) {
      // have to use for loop instead of $.each, as the latter turns "this"
      // into an object even if it's a string :-/
      if (typeof errors[i] == "object") {
        html += '<li class="error-entry">';
        if (errors[i].link) {
          html += '<a href="' + errors[i].link + '">';
        }
        html += '<span class="ui-icon ui-icon-alert"></span> ';
        html += errors[i].msg;
        if (errors[i].link) {
          html += '</a>';
        }
        html += '</li>';
      } else {
        html += '<li>' + escape_html(errors[i]) + '</li>';
      }
    }
    html += '</ul>';
    $("#errorbar").html(html);
    $("#errorbar").show();
  } else {
    $("#errorbar").html("");
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

// Return a class:provider:type string
function cpt(res)
{
  var s = "";
  if (res['class']) {
    s += res['class'] + ':'
    if (res['provider']) { s += res['provider'] + ':'; }
    s += res['type'];
  }
  return s;
}

// Generic individual item (node or resource)
function new_item_div(id, title) {
  return $(
    '<div id="' + id + '"' + (title ? ' title="' + escape_html(title) + '"' : '') + '>' +
      '<a id="' + id + '::menu" title=""><img src="' + url_root + '/assets/transparent-16x16.gif" class="action-icon" alt="" /></a>' +
      '<div id="' + id + '::state" style="float: left; width: 16px; height: 16px;" title=""></div>' +
      '<div id="' + id + '::error" class="status-icons">' +
        '<span class="ui-icon ui-icon-alert" style="float: right; display: none;" />' +
        '<span class="ui-icon ui-icon-info" style="float: right; display: none;" />' +
        '<span class="ui-icon ui-icon-wrench" style="float: right; display: none;" />' +
      '</div>' +
      '<span id="' + id + '::label"></span>' +
    "</div>");
}

// Mark items with errors (just an icon at this stage, "error" is boolean)
function flag_error(id, failed_ops) {
  var e = $(jq(id+"::error")).find(".ui-icon-alert");
  if (failed_ops.length > 0) {
    var errs = [];
    $.each(failed_ops, function() {
      // TODO(should): Localize "ignored"
      var err = GETTEXT.err_failed_op(this.op, this.node, this.rc_code, this.exit_reason) + (this.ignored ? " (ignored)" : "");
      errs.push(escape_html(err));
    });
    e.attr("title", errs.join(", "));
    e.show();
  } else {
    e.removeAttr("title");
    e.hide();
  }
}

// This is slightly misnamed -- it does the same thing as flag_error, but for arbitrary
// text, as opposed to a list of failed ops.  Only one of flag_error() or flag_warning()
// can apply at a time (same icon).
function flag_warning(id, info) {
  var e = $(jq(id+"::error")).find(".ui-icon-alert");
  if (info) {
    e.attr("title", info);
    e.show();
  } else {
    e.removeAttr("title");
    e.hide();
  }
}

// Mark items with some info rollover
function flag_info(id, info) {
  var e = $(jq(id+"::error")).find(".ui-icon-info");
  if (info) {
    e.attr("title", info);
    e.show();
  } else {
    e.removeAttr("title");
    e.hide();
  }
}

function flag_maintenance(id, info) {
  var e = $(jq(id+"::error")).find(".ui-icon-wrench");
  if (info) {
    e.attr("title", info);
    e.show();
  } else {
    e.removeAttr("title");
    e.hide();
  }
}

// title: dialog title
// id:    node or resource id
// type:  either "node" or "resource"
// op:    op to perform
function confirm_op(title, id, type, op, extra)
{
  $("#dialog").html(GETTEXT[type + "_" + op](id));
  // TODO(could): Is there a neater construct for this localized button thing?
  var b = {};
  b[GETTEXT.yes()]  = function() { perform_op(type, id, op, extra); $(this).dialog("close"); };
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
  $(jq(type + "::" + id + "::menu")).children(":first").attr("src", url_root + "/assets/spinner-16x16-" + state + ".gif");

  $.ajax({ url: url_root + "/main/" + type + "/" + op,
    data: "format=json&" + type + "=" + id + (extra ? "&" + extra : "") + (cib_source != "file" ? "&cib_id=" + cib_source : ""),
    type: "POST",
    success: function() {
      // Remove spinner (a spinner that stops too early is marginally better than one that never stops)
      $(jq(type + "::" + id + "::menu")).children(":first").attr("src", url_root + "/assets/icons/properties.png");
    },
    error: function(request) {
      // Remove spinner
      $(jq(type + "::" + id + "::menu")).children(":first").attr("src", url_root + "/assets/icons/properties.png");
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

function get_top_parent_id(id) {
  var parent = null;
  $.each(resources_by_id, function() {
    if (!this.children) return;
    var cp = this.id;
    $.each(this.children, function() {
      if (this.id == id) {
        if (resources_by_id[cp].toplevel) {
          parent = cp;
        } else {
          parent = get_top_parent_id(cp);
        }
        return false;
      };
    });
  });
  return parent;
}

function add_mgmt_menu(e)
{
  e.addClass("clickable");
  e.children(":first").attr("src", url_root + "/assets/icons/properties.png");
  // parts[0] is "node" or "resource", parts[1] is node or resource ID
  var parts = dc_split(e.attr("id"));
  if (parts[0] == "node") {
    e.click(function() {
      return $(jq("menu::node")).popupmenu("popup", $(this));
    });
  } else if (parts[0] == "ticket") {
    e.click(function() {
      return $(jq("menu::ticket")).popupmenu("popup", $(this));
    });
  } else {
    var id_parts = parts[1].split(":");
    var is_clone_instance = id_parts.length == 2
    var tp = get_top_parent_id(id_parts[0]);
    if (id_parts.length == 2) {
      // It's a clone instance, hide everything except Edit, Delete, View Details/Events
      e.click(function() {
        return $(jq("menu::resource")).popupmenu("popup", $(this), [0, 1, 2, 3, 4, 5, 6, 7], {
          label: GETTEXT.resource_parent(tp),
          id: tp,
          fn: function() {
            // Toplevel submenu (same as below for other children)
            // This frightful injected span allows us to shove the correct parent ID
            // through to perform_op etc.
            var t = $('<span style="float:right;" id="submenu::' + tp + '"><span/></span>');
            $(e).append(t);
            var rv;
            if (resources_by_id[id_parts[0]].children && resources_by_id[id_parts[0]].type == "master") {
              rv = $(jq("menu::resource")).popupmenu("popup", t);
            } else {
              rv = $(jq("menu::resource")).popupmenu("popup", t, [4, 5]);
            }
            t.remove();
            return rv;
          }
        });
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
          return $(jq("menu::resource")).popupmenu("popup", $(this), [2, 3, 4, 5], {
            label: GETTEXT.resource_parent(tp),
            id: tp,
            fn: function() {
              // Toplevel submenu (same as above for clone instances)
              // This frightful injected span allows us to shove the correct parent ID
              // through to perform_op etc.
              var t = $('<span style="float:right;" id="submenu::' + tp + '"><span/></span>');
              $(e).append(t);
              var rv;
              if (resources_by_id[id_parts[0]].children && resources_by_id[id_parts[0]].type == "master") {
                rv = $(jq("menu::resource")).popupmenu("popup", t);
              } else {
                rv = $(jq("menu::resource")).popupmenu("popup", t, [4, 5]);
              }
              t.remove();
              return rv;
            }
          });
        });
      }
    }
  }
}

function do_update(cur_epoch)
{
  // No refresh if this is not the  live CIB
  if (cib_source != "live") return;

  update_req = $.ajax({ url: url_root + "/monitor?" + cur_epoch,
    type: "GET",
    cache: false,
    timeout: 90000,   // hawk_monitor timeout + 50% wiggle room
    success: function(data) {
      if (data) {
        if (data.epoch != cur_epoch || (cib && cib.booth && cib.booth.me)) {
          // Trigger full update if the epoch has changed, or if it's a geo-cluster;
          // this means geo clusters will get an update every minute or so, which
          // means if it's at all possible for booth status to drift without updating
          // the CIB, at least it will be apparent within a minute or so.
          update_cib();
        } else {
          do_update(data.epoch);
        }
      } else {
        // This can occur when onSuccess is called in FF on an
        // aborted request; re-request cib in 15 seconds (see also
        // beforeunload handler in hawk_init).
        update_errors([GETTEXT.err_conn_aborted()]);
        hide_status();
        setTimeout(update_cib, 15000);
      }
    },
    error: function(request) {
      // Busted, retry in 15 seconds.
      if (request.readyState > 1) {
        // Can't rely on request.status if not ready enough
        if (request.status >= 10000) {
          // Crazy winsock(?) error on IE when request aborted
          update_errors([GETTEXT.err_conn_failed()]);
        } else {
          update_errors([GETTEXT.err_unexpected(request.status + " " + request.statusText)]);
        }
      } else {
        // Request timed out
        update_errors([GETTEXT.err_conn_timeout()]);
      }
      hide_status();
      setTimeout(update_cib, 15000);
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
  }
  $.each(resources, function() {
    resources_by_id[this.id] = this;
    resources_by_id[this.id].toplevel = toplevel;
    if (this.children) {
      update_resources_by_id(this.children);
    }
  });
}

function hide_status()
{
  $("#dc_current").hide();
  $("#dc_version").hide();
  $("#dc_stack").hide();
  $("#view-switcher").hide();
  current_view.hide();
}

function update_cib()
{
  update_req = $.ajax({ url: url_root + "/cib/" + (cib_source == "file" ? cib_file : cib_source),
    timeout: 90000, // (same as do_update, arbitrarily -- can't be too short, but must be > 0)
    data: "format=json" + (cib_source == "file" ? "&debug=file" : ""),
    type: "GET",
    success: function(data) {
      $("#onload-spinner").hide();
      $("#view-switcher").show();
      if (data) {
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
          simulator.update();
        } else {
          // TODO(must): is it possible to get here with empty cib.errors?
          hide_status();
        }
        if (update_period && cib_source == "live") {
          // Handy when debugging...
          setTimeout(update_cib, update_period);
        } else {
          do_update(cib.meta ? cib.meta.epoch : "");
        }
      } else {
        // 'data' not set (this can occur when onSuccess is called
        // erroneously on request abort; re-request in 15 seconds)
        update_errors([GETTEXT.err_conn_aborted()]);
        hide_status();
        setTimeout(update_cib, 15000);
      }
    },
    error: function(request) {
      if (request.readyState > 1) {
        if (request.status == 403) {
          // 403 == permission denied, boot the user out
          window.location.replace(url_root + "/logout?reason=forbidden");
          return;
        } else {
          var json = json_from_request(request);
          if (json && json.errors) {
            // Sane response (server not dead, but actual error, e.g.:
            // access denied):
            update_errors(json.errors);
          } else {
            // Unexpectedly busted (e.g.: server fried):
            if (request.status >= 10000) {
              // Crazy winsock(?) error on IE
              update_errors([GETTEXT.err_conn_failed()]);
            } else {
              update_errors([GETTEXT.err_unexpected(request.status + " " + request.statusText)]);
            }
          }
        }
      } else {
        // Request timed out
        update_errors([GETTEXT.err_conn_timeout()]);
      }
      hide_status();
      if (cib_source != "live") {
        $("#onload-spinner").hide();
        $("#view-switcher").show();
      } else {
        // Try again in 15 seconds.  No need for roundtrip through
        // the monitor function in this case (it'll just hammer the
        // server unnecessarily)
        setTimeout(update_cib, 15000);
      }
    }
  });
}

function change_view(new_view) {
  if (current_view == new_view) return;
  current_view.hide();
  current_view = new_view;
  current_view.update();
  switch(current_view) {
    case panel_view:   $.cookie("hawk-status-view", "panel", { expires: 3650 });   break;
    case table_view:   $.cookie("hawk-status-view", "table", { expires: 3650 });   break;
    case summary_view: $.cookie("hawk-status-view", "summary", { expires: 3650 }); break;
  }
}

function hawk_init()
{
  var q = $.parseQuery();
  if (q.cib_file) {
    cib_source = "file";
    cib_file = q.cib_file;
  }
  if (q.cib_id) {
    cib_source = q.cib_id;
  }
  if (q.update_period) {
    update_period = isNaN(q.update_period) ? 0 : parseInt(q.update_period) * 1000;
  }

  summary_view.create();
  panel_view.create();
  table_view.create();
  simulator.create();

  var sc = "";
  var pc = "";
  var tc = "";
  // Default to summary view (need this in init, not raw, else we're dependent
  // on status-summary.js being included before status.js)
  switch($.cookie("hawk-status-view")) {
    case "panel":   current_view = panel_view;   pc = ' checked="checked"'; break;
    case "table":   current_view = table_view;   tc = ' checked="checked"'; break;
    case "summary": // Summary is the default view
    default:        current_view = summary_view; sc = ' checked="checked"'; break;
  }

  // view switcher must be first thing in content after errorbar
  $("#errorbar").after($(
    '<div id="view-switcher" style="float: right;"><form>' +
      '<input id="view-summary" name="view-radio" type="radio"' + sc + ' /><label for="view-summary">' + GETTEXT.summary_view() + "</label>" +
      '<input id="view-panel" name="view-radio" type="radio"' + pc + ' /><label for="view-panel">' + GETTEXT.tree_view() + "</label>" +
      '<input id="view-table" name="view-radio" type="radio"' + tc + ' /><label for="view-table">' + GETTEXT.table_view() + "</label>" +
    "</form></div"));
  $("#view-switcher").buttonset();
  $("#view-summary").button("option", { icons: { primary: "icon-view-summary" }, text: false }).click(function() {
    change_view(summary_view);
  });
  $("#view-panel").button("option", { icons: { primary: "icon-view-panel" }, text: false }).click(function() {
    change_view(panel_view);
  });
  $("#view-table").button("option", { icons: { primary: "icon-view-table" }, text: false }).click(function() {
    change_view(table_view);
  });
  $("#view-switcher").hide();

  $(window).bind("beforeunload", function() {
    if (update_req) {
      // If our monitor/update request is around, wipe out its success function
      // when leaving the page, otherwise in FF the success triggers with empty
      // data, which is the same codepath we hit when the request aborts due to
      // (say) the Hawk process on the server being terminated.
      update_req.onreadystatechange = $.noop;
    }
  });

  if (cib_source != "file" && cib_source != "live") {
    simulator.activate();
  } else {
    update_cib();
  }
}
