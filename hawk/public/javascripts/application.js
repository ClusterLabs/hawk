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

function expand_block(id)
{
  new Effect.BlindDown($(id+'::children'), { duration: 0.3, fps: 100 });
  $(id+'::children').removeClassName('closed');
  $(id+'::button').removeClassName('tri-closed').addClassName('tri-open');
}

function collapse_block(id)
{
  new Effect.BlindUp($(id+'::children'), { duration: 0.3, fps: 100 });
  $(id+'::children').addClassName('closed');
  $(id+'::button').removeClassName('tri-open').addClassName('tri-closed');
}

// TODO(should): for another approach to expand/contract, see
// http://www.kleenecode.net/2008/03/01/valid-and-accessible-collapsible-panels-with-scriptaculous/
function toggle_collapse(id)
{
  if ($(id+'::children').hasClassName('closed')) {
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
      $("errorbar").insert($(document.createElement("div")).addClassName('error').update(e));
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
  var changed = ($(panel.id).className != panel.className || $(panel.id+"::label").innerHTML != panel.label);

  $(panel.id).className = panel.className;
  $(panel.id+"::label").update(panel.label);

  // If something changed, turn the spinner back into a properties icon
  if (changed && $(panel.id+"::menu").firstDescendant().src.indexOf("spinner") != -1) {
    $(panel.id+"::menu").firstDescendant().src = "/images/icons/properties.png";
  }

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
              '<a id="' + item.id + '::menu" class="menu-link"><img src="/images/transparent-16x16.gif" class="action-icon" alt="" /></a>' +
              '<span id="' + item.id + '::label"></span></div>' +
            '<div id="' + item.id + '::children"' + (item.open ? ' style="display: none;" class="closed"' : '') + '</div>');
        } else {
          d.update('<a id="' + item.id + '::menu" class="menu-link"><img src="/images/transparent-16x16.gif" class="action-icon" alt="" /></a><span id="' + item.id + '::label"></span>');
        }
      }
      if (!c) {
        $(panel.id+"::children").insert(d);
      } else {
        c.insert({before: d});
      }
      add_mgmt_menu($(item.id + "::menu"));
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

// Um...  what's "object" for?
function handle_update(request, object)
{
  // TODO(should): really should be using Ajax.Request onSuccess to
  // trigger this callback...
  if (request.responseJSON) {
    update_errors(request.responseJSON.errors);

    if (request.responseJSON.cib_up) {
      $("summary").show();
      update_summary(request.responseJSON.summary);

      $("nodelist").show();
      if (update_panel(request.responseJSON.nodes)) {
        if ($("nodelist::children").hasClassName("closed")) {
          expand_block("nodelist");
        }
      }

      $("reslist").show();
      if (update_panel(request.responseJSON.resources)) {
        if ($("reslist::children").hasClassName("closed")) {
          expand_block("reslist");
        }
      }
    } else {
      $("summary").hide();
      $("nodelist").hide();
      $("reslist").hide();
    }
  }
  do_update();
}

// Like string.split, but breaks on '::'
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

function perform_op(type, id, op)
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
  $(type + "::" + id + "::menu").firstDescendant().src = "/images/spinner-16x16-" + state + ".gif";

  new Ajax.Request("/main/" + type + "_" + op, {
    parameters: type + "=" + id,
    onSuccess:  function(request) {
      // Do nothing (spinner will stop when next full refresh occurs
    },
    onFailure:  function(request) {
      // Remove spinner
      $(type + "::" + id + "::menu").firstDescendant().src = "/images/icons/properties.png";
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
      e.firstDescendant().src = "/images/icons/properties.png";
      break;
    case "resource":
      if (e.parentNode.parentNode.hasClassName("res-clone")) {
        e.addClassName("clickable");
        e.observe("click", popup_op_menu);
        e.firstDescendant().src = "/images/icons/properties.png";
      } else {
        isClone = false;
        var n = e.parentNode;
        while (n && n.id != "reslist") {
          if (n.hasClassName("res-clone")) {
            isClone = true;
            break;
          }
          n = n.parentNode;
        }
        if (!isClone) {
          e.addClassName("clickable");
          e.observe("click", popup_op_menu);
          e.firstDescendant().src = "/images/icons/properties.png";
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
  $("menu::resource::cleanup").firstDescendant().observe("click", menu_item_click);

  document.observe('click', function(e) {
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
    $("dialog-body").update(params.body.escapeHTML().replace(/\n/g, "<br />")).show();
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
    $("dialog-buttons").update('<button onclick="hide_modal_dialog();">' + GETTEXT.ok() + '</button>');
  }

  // Dialog is always 100px below viewport top, but need to center it
  // TODO(could): can this be done with CSS only?
  // TODO(should): move horizontally when window resizes
  var style = { left: (document.viewport.getWidth() / 2 - $("dialog").getWidth() / 2) + 'px' };
  if ($("dialog").getStyle("position") == "absolute") {
    // Hacks to make IE6 suck a little bit less.
    var offsets = document.viewport.getScrollOffsets();
    // It doesn't support fixed position, so move the dialog so it's 100px below
    // the top of the viewport:
    style.top = (offsets.top + 100) + 'px';
    // It also treats 100% width and height of overlay as relative to viewport,
    // not document, so move the overlay so it's in the current viewport.
    $("overlay").setStyle({left: offsets.left + 'px', top: offsets.top + 'px'});
  }
  $("overlay").setOpacity(0.5).show();
  $("dialog").setStyle(style).show();
}

function do_update()
{
  setTimeout("new Ajax.Request('/main/status', { parameters: 'format=json', asynchronous: true, onComplete: handle_update });", 15000);
}

