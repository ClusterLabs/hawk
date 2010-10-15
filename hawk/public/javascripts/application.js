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

function expand_block(id)
{
  new Effect.BlindDown($(id+"::children"), { duration: 0.3, fps: 100 });
  $(id+"::children").removeClassName("closed");
  $(id+"::button").removeClassName("tri-closed").addClassName("tri-open");
}

function collapse_block(id)
{
  new Effect.BlindUp($(id+"::children"), { duration: 0.3, fps: 100 });
  $(id+"::children").addClassName("closed");
  $(id+"::button").removeClassName("tri-open").addClassName("tri-closed");
}

// TODO(should): for another approach to expand/contract, see
// http://www.kleenecode.net/2008/03/01/valid-and-accessible-collapsible-panels-with-scriptaculous/
function toggle_collapse(id)
{
  if ($(id+"::children").hasClassName("closed")) {
    expand_block(id);
  } else {
    collapse_block(id);
  }
}


function update_errors(errors)
{
  $("errorbar").update("");
  if (errors.size()) {
    $("errorbar").show();
    errors.each(function(e) {
      $("errorbar").insert($(document.createElement("div")).addClassName("error").update(e));
    });
  } else {
    $("errorbar").hide();
  }
}

function update_summary(summary)
{
  for (var e in summary) {
    $("summary::" + e).update(summary[e]);
  }
}

// need to pass parent in with open flag (e.g.: nodelist, reslist)
function update_panel(panel)
{
  $(panel.id).className = panel.className;
  $(panel.id+"::label").update(panel.label);

  if (!panel.children) return false;

  var expand = panel.open ? true : false;   // do we really need to be this obscure?
  var c = $(panel.id+"::children").firstDescendant();
  panel.children.each(function(item) {
    if (!c || c.readAttribute("id") != item.id) {
      var d;
      if ($(item.id)) {
        // already got one for this resource, tear it out and reuse it.
        d = $(item.id).remove();
      } else {
        // brand spanking new
        d = $(document.createElement("div")).writeAttribute("id", item.id);
        if (item.children) {
          // TODO(should): HTML-safe?
          d.update('<div class="clickable" onclick="toggle_collapse(\'' + item.id + '\');">' +
            '<div id="' + item.id + '::button" class="tri-' + (item.open ? 'open' : 'closed') + '"></div>' +
              '<a id="' + item.id + '::menu" class="menu-link"><img src="../images/transparent-16x16.gif" class="action-icon" alt="" /></a>' +
              '<span id="' + item.id + '::label"></span></div>' +
            '<div id="' + item.id + '::children"' + (item.open ? '' : ' style="display: none;" class="closed"') + '</div>');
        } else {
          d.update('<a id="' + item.id + '::menu" class="menu-link"><img src="../images/transparent-16x16.gif" class="action-icon" alt="" /></a><span id="' + item.id + '::label"></span>');
        }
      }
      if (!c) {
        $(panel.id+"::children").insert(d);
      } else {
        c.insert({before: d});
      }
      if (!cib_file) {
        // Only add menus if this isn't a static test
        add_mgmt_menu($(item.id + "::menu"));
      }
    } else {
      c = c.next();
    }
    if (update_panel(item)) {
      if ($(item.id + "::children").hasClassName("closed")) {
        expand_block(item.id);
      }
      expand = true;
    }
  });
  // If there's any child nodes left, get rid of 'em
  while (c) {
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

function popup_op_menu(e)
{
  var target = Event.element(e);
  var pos = target.cumulativeOffset();
  // parts[0] is "node" or "resource", parts[1] is op
  var parts = dc_split(target.parentNode.id);
  activeItem = parts[1];
  // Special case to show/hide migrate (only visible at top level, not children of groups)
  // TODO(should): in general we need a better way of understanding the cluster hierarchy
  // from here than walking the DOM tree - it's too dependant on too many things.
  if (parts[0] == "resource") {
    var c = 0;
    var isMs = false;
    var n = $(target.parentNode);
    while (n && n.id != "reslist") {
      if (n.hasClassName("res-primitive") || n.hasClassName("res-clone") || n.hasClassName("res-group")) {
        c++;
      }
      if (n.hasClassName("res-ms")) {
        isMs = true;
      }
      n = $(n.parentNode);
    }
    if (c == 1) {
      // Top-level item (for primitive in group this would be 2)
      $("menu::resource::migrate").show();
      $("menu::resource::unmigrate").show();
    } else {
      $("menu::resource::migrate").hide();
      $("menu::resource::unmigrate").hide();
    }
    if (isMs) {
      $("menu::resource::promote").show();
      $("menu::resource::demote").show();
    } else {
      $("menu::resource::promote").hide();
      $("menu::resource::demote").hide();
    }
  }
  $("menu::" + parts[0]).setStyle({left: pos.left+"px", top: pos.top+"px"}).show();
  Event.stop(e);
}

function menu_item_click(e)
{
  // parts[1] is "node" or "resource", parts[2] is op
  var parts = dc_split(Event.element(e).parentNode.id);
  modal_dialog(GETTEXT[parts[1] + "_" + parts[2]](activeItem),
    { buttons: [
      // TODO(should): This is a bit hairy - we might be better off passing
      // functions around than doing this generated onclick code thing...
      { label: GETTEXT.yes(), action: "perform_op('" + parts[1] + "','" + activeItem + "','" + parts[2] + "');" },
      { label: GETTEXT.no() }
    ] });
}

function menu_item_click_migrate(e)
{
  // parts[1] is "node" or "resource", parts[2] is op
  var parts = dc_split(Event.element(e).parentNode.id);
  var html = '<form><select id="migrate-to" size="4" style="width: 100%;">';
  // TODO(should): Again, too much dependence on DOM structure here
  $("nodelist::children").childElements().each(function(e) {
    var node = dc_split(e.id)[1];
    html += '<option value="' + node + '">' + GETTEXT.resource_migrate_to(node) + "</option>\n";
  });
  html += '<option selected="selected" value="">' + GETTEXT.resource_migrate_away() + "</option>\n";
  html += "</form></select>";
  modal_dialog(GETTEXT[parts[1] + "_" + parts[2]](activeItem),
    { body_raw: html,
      buttons: [
      { label: GETTEXT.ok(), action: "perform_op('" + parts[1] + "','" + activeItem + "','" + parts[2] + "','node=' + $('migrate-to').getValue());" },
      { label: GETTEXT.cancel() }
    ] });
}

function perform_op(type, id, op, extra)
{
  var state = "neutral";
  var c = $(type + "::" + id);
  if (c.hasClassName("ns-active"))         state = "active";
  else if(c.hasClassName("ns-inactive"))  state = "inactive";
  else if(c.hasClassName("ns-error"))     state = "error";
  else if(c.hasClassName("ns-transient")) state = "transient";
  else if(c.hasClassName("rs-active"))    state = "active";
  else if(c.hasClassName("rs-inactive"))  state = "inactive";
  else if(c.hasClassName("rs-error"))     state = "error";
  $(type + "::" + id + "::menu").firstDescendant().src = "../images/spinner-16x16-" + state + ".gif";

  new Ajax.Request("../main/" + type + "/" + op, {
    parameters: type + "=" + id + (extra ? "&" + extra : ""),
    onSuccess:  function(request) {
      // Remove spinner (a spinner that stops too early is marginally better than one that never stops)
      $(type + "::" + id + "::menu").firstDescendant().src = "../images/icons/properties.png";
    },
    onFailure:  function(request) {
      // Remove spinner
      $(type + "::" + id + "::menu").firstDescendant().src = "../images/icons/properties.png";
      // Display error
      if (request.responseJSON) {
        modal_dialog(request.responseJSON.error,
          { body: (request.responseJSON.stderr && request.responseJSON.stderr.size()) ? request.responseJSON.stderr.join("\n") : null });
      } else {
        modal_dialog(GETTEXT.err_unexpected(request.status));
      }
    }
  });
}

function add_mgmt_menu(e)
{
  switch (dc_split(e.id)[0]) {
    case "node":
      e.addClassName("clickable");
      e.observe("click", popup_op_menu);
      e.firstDescendant().src = "../images/icons/properties.png";
      break;
    case "resource":
      if ($(e.parentNode.parentNode).hasClassName("res-clone")) {
        e.addClassName("clickable");
        e.observe("click", popup_op_menu);
        e.firstDescendant().src = "../images/icons/properties.png";
      } else {
        var isClone = false;
        var n = e.parentNode;
        while (n && n.id != "reslist") {
          if ($(n).hasClassName("res-clone")) {
            isClone = true;
            break;
          }
          n = n.parentNode;
        }
        if (!isClone) {
          e.addClassName("clickable");
          e.observe("click", popup_op_menu);
          e.firstDescendant().src = "../images/icons/properties.png";
        }
      }
      break;
  }
}

function init_menus()
{
  $("menu::node::standby").firstDescendant().observe("click", menu_item_click);
  $("menu::node::online").firstDescendant().observe("click", menu_item_click);
  $("menu::node::fence").firstDescendant().observe("click", menu_item_click);
//  $("menu::node::mark").firstDescendant().observe("click", menu_item_click);

  $("menu::resource::start").firstDescendant().observe("click", menu_item_click);
  $("menu::resource::stop").firstDescendant().observe("click", menu_item_click);
  $("menu::resource::migrate").firstDescendant().observe("click", menu_item_click_migrate);
  $("menu::resource::unmigrate").firstDescendant().observe("click", menu_item_click);
  $("menu::resource::promote").firstDescendant().observe("click", menu_item_click);
  $("menu::resource::demote").firstDescendant().observe("click", menu_item_click);
  $("menu::resource::cleanup").firstDescendant().observe("click", menu_item_click);

  document.observe("click", function(e) {
    $("menu::node").hide();
    $("menu::resource").hide();
  });

  $$(".menu-link").each(add_mgmt_menu);
}

function hide_modal_dialog()
{
  $("dialog").hide();
  $("overlay").hide();
}

function modal_dialog(msg, params)
{
  params = params || {};

  $("dialog-message").update(msg.escapeHTML());

  if (params.body) {
    if (!$("dialog-body").hasClassName("message")) {
      $("dialog-body").addClassName("message");
    }
    $("dialog-body").update(params.body.escapeHTML().replace(/\n/g, "<br />")).show();
  } else if (params.body_raw) {
    $("dialog-body").removeClassName("message");
    $("dialog-body").update(params.body_raw).show();
  } else {
    $("dialog-body").hide();
  }

  if (params.buttons) {
    var html = "";
    params.buttons.each(function(button) {
      html += '<button onclick="' + (button.action ? button.action : '') + ' hide_modal_dialog();">' + button.label + '</button> ';
    });
    $("dialog-buttons").update(html);
  } else {
    $("dialog-buttons").update('<button onclick="hide_modal_dialog();">' + GETTEXT.ok() + "</button>");
  }

  // Dialog is always 100px below viewport top, but need to center it
  // TODO(could): can this be done with CSS only?
  // TODO(should): move horizontally when window resizes
  var style = { left: (document.viewport.getWidth() / 2 - $("dialog").getWidth() / 2) + "px" };
  if ($("dialog").getStyle("position") == "absolute") {
    // Hacks to make IE6 suck a little bit less.
    var offsets = document.viewport.getScrollOffsets();
    // It doesn't support fixed position, so move the dialog so it's 100px below
    // the top of the viewport:
    style.top = (offsets.top + 100) + "px";
    // It also treats 100% width and height of overlay as relative to viewport,
    // not document, so move the overlay so it's in the current viewport.
    $("overlay").setStyle({left: offsets.left + "px", top: offsets.top + "px"});
  }
  if (Prototype.Browser.MobileSafari) {
    // Hack to fold back to absolute positioning on e.g. Android
    // which can't cope with fixed position when zoomed in.  Not
    // optimal, but better than a dialog you can't use!
    style.position = "absolute";
  }
  $("overlay").setOpacity(0.5).show();
  $("dialog").setStyle(style).show();
}

function do_update(cur_epoch)
{
  // No refresh if this is a static test
  if (cib_file) return;

  new Ajax.Request("../monitor?" + cur_epoch, { method: "get",
    onSuccess: function(transport) {
      if (transport.responseJSON) {
        var new_epoch = transport.responseJSON ? transport.responseJSON.epoch : "";
        if (new_epoch != cur_epoch) {
          update_cib();
        } else {
          do_update(new_epoch);
        }
      } else {
        // This can occur when onSuccess is called erroneously
        // on network failure; re-request in 15 seconds
        setTimeout("do_update('" + cur_epoch + "')", 15000);
      }
    },
    onFailure: function(transport) {
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
    label:      GETTEXT.nodes_configured(nodes.size()),
    open:       false,
    children:   []
  };
  nodes.each(function(n) {
    var className;
    var label = GETTEXT.node_state_unknown();
    switch (n.state) {
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
    if (n.state != "online") {
      panel.open = true;
    }
    panel.children.push({
      id:         "node::" + n.uname,
      className:  "node ns-" + className,
      label:      GETTEXT.node_state(n.uname, label),
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
  res.children.each(function(c) {
    var set = get_primitive(c);
    set.each(function(i) {
      if (!groups[i.instance]) {
        instances.push(i.instance);
        groups[i.instance] = {
          id:        "resource::" + res.id,
          className: "res-group rs-active",
          label:     GETTEXT.resource_group(res.id),
          open:      false,
          children:  []
        };
        if (i.instance != "default") {
          groups[i.instance].id += ":" + i.instance;
          groups[i.instance].label += ":" + i.instance;
        }
      }
      if (!i.active) {
        groups[i.instance].open = true;
        groups[i.instance].className = "res-group rs-inactive";
      }
      groups[i.instance].children.push(i);
    });
  });
  set = []
  instances.sort().each(function(i) {
    set.push(groups[i]);
  });
  return set;
}

function get_clone(res)
{
  var status_class = "rs-active";
  var children = [];
  var open = false;
  res.children.each(function(p) {
    if (p.type == "group") {
      var set = get_group(p);
      set.each(function(c) {
        if (c.open) open = true;
        if (c.className.indexOf("rs-active") == -1) status_class = "rs-inactive";
        children.push(c);
      });
    } else {
      var set = get_primitive(p);
      set.each(function(c) {
        if (!c.active) {
          open = true;
          status_class = "rs-inactive";
        }
        children.push(c);
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
    label:      GETTEXT.resources_configured(resources.size()),
    open:       false,
    children:   []
  };
  resources.each(function(res) {
    var c = null;
    if (res.children) {
      if (res.type == "group") {
        c = get_group(res)[0];
        if (c.open) panel.open = true;
      } else if (res.type == "clone" || res.type == "master") {
        c = get_clone(res);
        if (c.open) panel.open = true;
      }
    } else {
      c = get_primitive(res)[0];
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
  new Ajax.Request("../cib/" + (cib_file ? cib_file + "?debug=file" : "live"), { method: "get",
    onSuccess: function(transport) {
      $("onload-spinner").hide();
      if (transport.responseJSON) {
        cib = transport.responseJSON;
        update_errors(cib.errors);
        if (cib.meta) {
          $("summary").show();
          $("summary::dc").update(cib.meta.dc);
          for (var e in cib.crm_config) {
            if (!$("summary::" + e)) continue;
            if (typeof(cib.crm_config[e]) == "boolean") {
              $("summary::" + e).update(cib.crm_config[e] ? GETTEXT.yes() : GETTEXT.no())
            } else if(e == "dc_version") {
              var v = cib.crm_config[e];
              $("summary::" + e).update(cib.crm_config[e].match(/.*-[a-f0-9]{12}/));
            } else {
              $("summary::" + e).update(cib.crm_config[e].toString());
            }
          }

          $("nodelist").show();
          if (update_panel(cib_to_nodelist_panel(cib.nodes))) {
            if ($("nodelist::children").hasClassName("closed")) {
              expand_block("nodelist");
            }
          }

          $("reslist").show();
          if (update_panel(cib_to_reslist_panel(cib.resources))) {
            if ($("reslist::children").hasClassName("closed")) {
              expand_block("reslist");
            }
          }

        } else {
          // TODO(must): is it possible to get here with empty cib.errors?
          $("summary").hide();
          $("nodelist").hide();
          $("reslist").hide();
        }
      }
      do_update(cib.meta ? cib.meta.epoch : "");
    },
    onFailure: function(transport) {
      // Busted, try monitor immeidately (which will back off to
      // every 15 seconds if the server is completely fried).
      update_errors([GETTEXT.err_unexpected(transport.status + " " + transport.statusText)]);
      do_update("");
    }
  });
}

function hawk_init()
{
  var q = window.location.search.parseQuery();
  if (q.cib_file) {
    cib_file = q.cib_file;
  }

  init_menus();

  var sp = $(document.createElement("div")).writeAttribute("id", "summary");
  sp.update(
    '<table>' +
      '<tr><th>' + GETTEXT.summary_stack() + '</th><td><span id="summary::cluster_infrastructure"></span></td></tr>' +
      '<tr><th>' + GETTEXT.summary_version() + '</th><td><span id="summary::dc_version"></span></td></tr>' +
      '<tr><th>' + GETTEXT.summary_dc() + '</th><td><span id="summary::dc"></span></td></tr>' +
      '<tr><th>' + GETTEXT.summary_stickiness() + '</th><td><span id="summary::default_resource_stickiness"></span></td></tr>' +
      '<tr><th>' + GETTEXT.summary_stonith_enabled() + '</th><td><span id="summary::stonith_enabled"></span></td></tr>' +
      '<tr><th>' + GETTEXT.summary_symmetric() + '</th><td><span id="summary::symmetric_cluster"></span></td></tr>' +
      '<tr><th>' + GETTEXT.summary_no_quorum_policy() + '</th><td><span id="summary::no_quorum_policy"></span></td></tr>' +
    '</table>');
  sp.hide();
  $("content").insert({top: sp});
  var np = $(document.createElement("div")).writeAttribute("id", "nodelist");
  np.update(
    '<div class="clickable" onclick="toggle_collapse(\'nodelist\');"><div id="nodelist::button" class="tri-closed"></div><a id="nodelist::menu" class="menu-link"><img src="../images/transparent-16x16.gif" class="action-icon" alt="" /></a><span id="nodelist::label"></span></div>' +
      '<div id="nodelist::children" style="display: none;" class="closed"></div>' +
    '</div>');
  np.hide();
  sp.insert({after: np});
  var rp = $(document.createElement("div")).writeAttribute("id", "reslist");
  rp.update(
    '<div class="clickable" onclick="toggle_collapse(\'reslist\');"><div id="reslist::button" class="tri-closed"></div><a id="reslist::menu" class="menu-link"><img src="../images/transparent-16x16.gif" class="action-icon" alt="" /></a><span id="reslist::label"></span></div>' +
      '<div id="reslist::children" style="display: none;" class="closed"></div>' +
    '</div>');
  rp.hide();
  np.insert({after: rp});

  update_cib();
}
