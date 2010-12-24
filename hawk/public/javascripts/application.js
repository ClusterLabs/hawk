//======================================================================
//                        HA Web Konsole (Hawk)
// --------------------------------------------------------------------
//            A web-based GUI for managing and monitoring the
//          Pacemaker High-Availability cluster resource manager
//
// Copyright (c) 2009-2010 Novell Inc., Tim Serong <tserong@novell.com>
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

// Currently selected resource/node when menu is open
var activeItem = null;

var cib = null;
var cib_file = false;

function jq(id)
{
  return "#" + id.replace(/(:|\.)/g,'\\$1');
}

// Shame jQuery doesn't seem to give us JSON automatically in the case of an error...
function json_from_request(request)
{
  try {
    return $.parseJSON(request.responseText);
  } catch (e) {
    // This'll happen if the JSON is malformed somehow
    return null;
  }
}

function escape_html(str)
{
  return $("<div/>").text(str).html();
}

// TODO(should): clean up these three...
function expand_block(id)
{
  $(jq(id+"::children")).show("blind", {}, "fast");
  $(jq(id+"::children")).removeClass("closed");
  $(jq(id+"::button")).removeClass("tri-closed").addClass("tri-open");
}

function collapse_block(id)
{
  $(jq(id+"::children")).hide("blind", {}, "fast");
  $(jq(id+"::children")).addClass("closed");
  $(jq(id+"::button")).removeClass("tri-open").addClass("tri-closed");
}

function toggle_collapse(id)
{
  if ($(jq(id+"::children")).hasClass("closed")) {
    expand_block(id);
  } else {
    collapse_block(id);
  }
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

// need to pass parent in with open flag (e.g.: nodelist, reslist)
function update_panel(panel)
{
  $(jq(panel.id)).attr("class", "ui-corner-all " + panel.className);
  $(jq(panel.id+"::label")).html(panel.label);

  if (!panel.children) return false;

  var expand = panel.open ? true : false;   // do we really need to be this obscure?
  var c = $(jq(panel.id+"::children")).children(":first");
  $.each(panel.children, function() {
    if (!c.length || c.attr("id") != this.id) {
      var d;
      if ($(jq(this.id)).length) {
        // already got one for this resource, tear it out and reuse it.
        d = $(jq(this.id)).detach();
      } else {
        // brand spanking new
        d = $('<div id="' + this.id + '"/>');
        if (this.children) {
          // TODO(should): HTML-safe?
          d.html('<div class="clickable" onclick="toggle_collapse(\'' + this.id + '\');">' +
            '<div id="' + this.id + '::button" class="tri-' + (this.open ? 'open' : 'closed') + '"></div>' +
              '<a id="' + this.id + '::menu" class="menu-link"><img src="' + url_root + '/images/transparent-16x16.gif" class="action-icon" alt="" /></a>' +
              '<span id="' + this.id + '::label"></span></div>' +
            '<div id="' + this.id + '::children"' + (this.open ? '' : ' style="display: none;" class="closed"') + '</div>');
        } else {
          d.html('<a id="' + this.id + '::menu" class="menu-link"><img src="' + url_root + '/images/transparent-16x16.gif" class="action-icon" alt="" /></a><span id="' + this.id + '::label"></span>');
        }
      }
      if (!c.length) {
        $(jq(panel.id+"::children")).append(d);
      } else {
        c.before(d);
      }
      if (!cib_file) {
        // Only add menus if this isn't a static test
        add_mgmt_menu($(jq(this.id + "::menu")));
      }
    } else {
      c = c.next();
    }
    if (update_panel(this)) {
      if ($(jq(this.id + "::children")).hasClass("closed")) {
        expand_block(this.attr("id"));
      }
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

function popup_op_menu()
{
  // Hide everything first (otherwise it's actually possible to have
  // node and resource context menus visible simultaneously
  $(jq("menu::node")).hide();
  $(jq("menu::resource")).hide();

  var target = $(this);
  var pos = target.children(":first").offset();
  // parts[0] is "node" or "resource", parts[1] is op
  var parts = dc_split(target.attr("id"));
  activeItem = parts[1];
  // Special case to show/hide migrate (only visible at top level, not children of groups)
  // TODO(should): in general we need a better way of understanding the cluster hierarchy
  // from here than walking the DOM tree - it's too dependant on too many things.
  if (parts[0] == "resource") {
    var c = 0;
    var isMs = false;
    var n = target.parent();
    while (n.length && n.attr("id") != "reslist") {
      if (n.hasClass("res-primitive") || n.hasClass("res-clone") || n.hasClass("res-group")) {
        c++;
      }
      if (n.hasClass("res-ms")) {
        isMs = true;
      }
      n = n.parent();
    }
    if (c == 1) {
      // Top-level item (for primitive in group this would be 2)
      $(jq("menu::resource::migrate")).show();
      $(jq("menu::resource::unmigrate")).show();
    } else {
      $(jq("menu::resource::migrate")).hide();
      $(jq("menu::resource::unmigrate")).hide();
    }
    if (isMs) {
      $(jq("menu::resource::promote")).show();
      $(jq("menu::resource::demote")).show();
    } else {
      $(jq("menu::resource::promote")).hide();
      $(jq("menu::resource::demote")).hide();
    }
  }
  $(jq("menu::" + parts[0])).css({left: pos.left+"px", top: pos.top+"px"}).show();
  // Stop propagation
  return false;
}

function menu_item_click()
{
  // parts[1] is "node" or "resource", parts[2] is op
  var parts = dc_split($(this).attr("id"));
  $("#dialog").html(GETTEXT[parts[1] + "_" + parts[2]](activeItem));
  // TODO(could): Is there a neater construct for this localized button thing?
  var b = {};
  b[GETTEXT.yes()]  = function() { perform_op(parts[1], activeItem, parts[2]); $(this).dialog("close"); };
  b[GETTEXT.no()]   = function() { $(this).dialog("close"); }
  $("#dialog").dialog("option", {
    title:    $(this).children(":first").html(),
    buttons:  b
  });
  $("#dialog").dialog("open");
}

function menu_item_click_migrate()
{
  // parts[1] is "node" or "resource", parts[2] is op
  var parts = dc_split($(this).attr("id"));
  var html = '<form><select id="migrate-to" size="4" style="width: 100%;">';
  // TODO(should): Again, too much dependence on DOM structure here
  $(jq("nodelist::children")).children().each(function() {
    var node = dc_split($(this).attr("id"))[1];
    html += '<option value="' + node + '">' + GETTEXT.resource_migrate_to(node) + "</option>\n";
  });
  html += '<option selected="selected" value="">' + GETTEXT.resource_migrate_away() + "</option>\n";
  html += "</form></select>";
  $("#dialog").html(html);
  // TODO(could): Is there a neater construct for this localized button thing?
  var b = {};
  b[GETTEXT.ok()] = function() {
    perform_op(parts[1], activeItem, parts[2], "node=" + $("migrate-to").getValue());
    $(this).dialog("close");
  };
  b[GETTEXT.cancel()] = function() {
    $(this).dialog("close");
  };
  $("#dialog").dialog("option", {
    title:    GETTEXT[parts[1] + "_" + parts[2]](activeItem),
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
  switch (dc_split(e.attr("id"))[0]) {
    case "node":
      e.addClass("clickable");
      e.click(popup_op_menu);
      e.children(":first").attr("src", url_root + "/images/icons/properties.png");
      break;
    case "resource":
      if (e.parent().parent().hasClass("res-clone")) {
        e.addClass("clickable");
        e.click(popup_op_menu);
        e.children(":first").attr("src", url_root + "/images/icons/properties.png");
      } else {
        var isClone = false;
        var n = e.parent();
        while (n && n.attr("id") != "reslist") {
          if (n.hasClass("res-clone")) {
            isClone = true;
            break;
          }
          n = n.parent();
        }
        if (!isClone) {
          e.addClass("clickable");
          e.click(popup_op_menu);
          e.children(":first").attr("src", url_root + "/images/icons/properties.png");
        }
      }
      break;
  }
}

function init_menus()
{
  // TODO(should): re-evaluate use of 'first' here
  $(jq("menu::node::standby")).first().click(menu_item_click);
  $(jq("menu::node::online")).first().click(menu_item_click);
  $(jq("menu::node::fence")).first().click(menu_item_click);
//  $(jq("menu::node::mark")).first().click(menu_item_click);

  $(jq("menu::resource::start")).first().click(menu_item_click);
  $(jq("menu::resource::stop")).first().click(menu_item_click);
  $(jq("menu::resource::migrate")).first().click(menu_item_click_migrate);
  $(jq("menu::resource::unmigrate")).first().click(menu_item_click);
  $(jq("menu::resource::promote")).first().click(menu_item_click);
  $(jq("menu::resource::demote")).first().click(menu_item_click);
  $(jq("menu::resource::cleanup")).first().click(menu_item_click);

  $(document).click(function() {
    $(jq("menu::node")).hide();
    $(jq("menu::resource")).hide();
  });
}

function error_dialog(msg, body)
{
  if (body) {
    // TODO(should): theme this properly
    msg += '<div id="dialog-body" class="message">' + escape_html(body).replace(/\n/g, "<br />") + "</div>";
  }
  $("#dialog").html(msg);
  // TODO(could): Is there a neater construct for this localized button thing?
  var b = {};
  b[GETTEXT.ok()]   = function() { $(this).dialog("close"); }
  $("#dialog").dialog("option", {
    title:    GETTEXT.error(),
    buttons:  b
  });
  $("#dialog").dialog("open");
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

function cib_to_nodelist_panel(nodes)
{
  var panel = {
    id:         "nodelist",
    className:  "",
    style:      "",
    label:      GETTEXT.nodes_configured(nodes.length),
    open:       false,
    children:   []
  };
  $.each(nodes, function() {
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
      menu:       true
    });
  });
  return panel;
}

// TODO(must): sort order for injected instances might be wrong
function get_primitive(res)
{
  var set = [];
  for (var i in res.instances) {
    var id = res.id;
    if (i != "default") id += ":" + i;
    var status_class = "res-primitive";
    var label;
    var active = false;
    if (res.instances[i].master) {
      label = GETTEXT.resource_state_master(id, res.instances[i].master);
      status_class += " rs-active rs-master";
      active = true;
    } else if (res.instances[i].slave) {
      label = GETTEXT.resource_state_slave(id, res.instances[i].slave);
      status_class += " rs-active rs-slave";
      active = true;
    } else if (res.instances[i].started) {
      label = GETTEXT.resource_state_started(id, res.instances[i].started);
      status_class += " rs-active";
      active = true;
    } else if (res.instances[i].pending) {
      label = GETTEXT.resource_state_pending(id, res.instances[i].pending);
      status_class += " rs-transient";
    } else {
      label = GETTEXT.resource_state_stopped(id);
      status_class += " rs-inactive";
    }
    set.push({
      id:         "resource::" + id,
      instance:   i,
      className:  status_class,
      label:      label,
      active:     active
    });
  }
  return set;
}

function get_group(res)
{
  var instances = [];
  var groups = {};
  $.each(res.children, function() {
    $.each(get_primitive(this), function() {
      if (!groups[this.instance]) {
        instances.push(this.instance);
        groups[this.instance] = {
          id:        "resource::" + res.id,
          className: "res-group rs-active",
          label:     GETTEXT.resource_group(res.id),
          open:      false,
          children:  []
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
}

function get_clone(res)
{
  var status_class = "rs-active";
  var children = [];
  var open = false;
  $.each(res.children, function() {
    if (this.type == "group") {
      $.each(get_group(this), function() {
        if (this.open) open = true;
        if (this.className.indexOf("rs-active") == -1) status_class = "rs-inactive";
        children.push(this);
      });
    } else {
      $.each(get_primitive(this), function() {
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
    children:   children
  };
}

function cib_to_reslist_panel(resources)
{
  var panel = {
    id:         "reslist",
    className:  "",
    style:      "",
    label:      GETTEXT.resources_configured(resources.length),
    open:       false,
    children:   []
  };
  $.each(resources, function() {
    var c = null;
    if (this.children) {
      if (this.type == "group") {
        c = get_group(this)[0];
        if (c.open) panel.open = true;
      } else if (this.type == "clone" || this.type == "master") {
        c = get_clone(this);
        if (c.open) panel.open = true;
      }
    } else {
      c = get_primitive(this)[0];
      if (!c.active) panel.open = true;
    }
    if (c) {
      panel.children.push(c);
    }
  });
  return panel;
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
        update_errors(cib.errors);
        if (cib.meta) {
          $("#summary").show();
          $(jq("summary::dc")).html(cib.meta.dc);
          for (var e in cib.crm_config) {
            if (!$(jq("summary::" + e))) continue;
            if (typeof(cib.crm_config[e]) == "boolean") {
              $(jq("summary::" + e)).html(cib.crm_config[e] ? GETTEXT.yes() : GETTEXT.no())
            } else if(e == "dc_version") {
              $(jq("summary::" + e)).html(cib.crm_config[e].match(/.*-[a-f0-9]{12}/).toString());
            } else {
              $(jq("summary::" + e)).html(cib.crm_config[e].toString());
            }
          }

          $("#nodelist").show();
          if (update_panel(cib_to_nodelist_panel(cib.nodes))) {
            if ($(jq("nodelist::children")).hasClass("closed")) {
              expand_block("nodelist");
            }
          }

          $("#reslist").show();
          if (update_panel(cib_to_reslist_panel(cib.resources))) {
            if ($(jq("reslist::children")).hasClass("closed")) {
              expand_block("reslist");
            }
          }

        } else {
          // TODO(must): is it possible to get here with empty cib.errors?
          $("#summary").hide();
          $("#nodelist").hide();
          $("#reslist").hide();
        }
      }
      do_update(cib.meta ? cib.meta.epoch : "");
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
        $("#summary").hide();
        $("#nodelist").hide();
        $("#reslist").hide();
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

function hawk_init()
{
  var q = $.parseQuery();
  if (q.cib_file) {
    cib_file = q.cib_file;
  }

  init_menus();

  $("#dialog").dialog({
    resizable:      false,
    width:          "30em",
    draggable:      false,
    modal:          true,
    autoOpen:       false,
    closeOnEscape:  true
  });

  // TOTHEME
  $("#content").prepend($(
    '<div id="summary" class="ui-widget-content ui-corner-all" style="display: none;">' +
      '<table>' +
        '<tr><th>' + GETTEXT.summary_stack() + '</th><td><span id="summary::cluster_infrastructure"></span></td></tr>' +
        '<tr><th>' + GETTEXT.summary_version() + '</th><td><span id="summary::dc_version"></span></td></tr>' +
        '<tr><th>' + GETTEXT.summary_dc() + '</th><td><span id="summary::dc"></span></td></tr>' +
        '<tr><td colspan="2" style="border-top: 1px solid #aaa;"></td></tr>' +
        '<tr><th>' + GETTEXT.summary_stickiness() + '</th><td><a href="../cib/live/crm_config/cib-bootstrap-options/edit"><img src="../images/icons/edit.png" class="action-icon" alt="' + GETTEXT.configure() + '" title="' + GETTEXT.configure() + '" style="float: right;" /></a><span id="summary::default_resource_stickiness"></span></td></tr>' +
        '<tr><th>' + GETTEXT.summary_stonith_enabled() + '</th><td><span id="summary::stonith_enabled"></span></td></tr>' +
        '<tr><th>' + GETTEXT.summary_symmetric() + '</th><td><span id="summary::symmetric_cluster"></span></td></tr>' +
        '<tr><th>' + GETTEXT.summary_no_quorum_policy() + '</th><td><span id="summary::no_quorum_policy"></span></td></tr>' +
      '</table>' +
    '</div>' +
    '<div id="nodelist" class="ui-corner-all" style="display: none;">' +
      '<div class="clickable" onclick="toggle_collapse(\'nodelist\');"><div id="nodelist::button" class="tri-closed"></div><a id="nodelist::menu" class="menu-link"><img src="' + url_root + '/images/transparent-16x16.gif" class="action-icon" alt="" /></a><span id="nodelist::label"></span></div>' +
      '<div id="nodelist::children" style="display: none;" class="closed"></div>' +
    '</div>' +
    '<div id="reslist" class="ui-corner-all" style="display: none;">' +
      '<div class="clickable" onclick="toggle_collapse(\'reslist\');"><div id="reslist::button" class="tri-closed"></div><a id="reslist::menu" class="menu-link"><img src="' + url_root + '/images/transparent-16x16.gif" class="action-icon" alt="" /></a><span id="reslist::label"></span></div>' +
      '<div id="reslist::children" style="display: none;" class="closed"></div>' +
    '</div>'));

  update_cib();
}
