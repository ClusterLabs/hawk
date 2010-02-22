// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

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

// TODO: for another approach to expand/contract, see
// http://www.kleenecode.net/2008/03/01/valid-and-accessible-collapsible-panels-with-scriptaculous/
function toggle_collapse(id)
{
  if ($(id+'::children').hasClassName('closed')) {
    expand_block(id);
  } else {
    collapse_block(id);
  }
}


function update_errors(errors) {
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

function update_summary(summary) {
  for (var e in summary) {
    $("summary::" + e).update(summary[e]);
  }
}

// need to pass parent in with open flag (e.g.: nodelist, reslist)
function update_panel(panel) {
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
          // TODO: HTML-safe?
          d.update('<div class="clickable" onclick="toggle_collapse(\'' + item.id + '\');">' +
            '<div id="' + item.id + '::button" class="tri-' + (item.open ? 'open' : 'closed') + '"></div>' +
              '<a id="' + item.id + '::menu"><img src="/images/transparent-16x16.gif" class="action-icon" alt="" /></a>' +
              '<span id="' + item.id + '::label"></span></div>' +
            '<div id="' + item.id + '::children"' + (item.open ? ' style="display: none;" class="closed"' : '') + '</div>');
        } else {
          d.update('<a id="' + item.id + '::menu"><img src="/images/transparent-16x16.gif" class="action-icon" alt="" /></a><span id="' + item.id + '::label"></span>');
        }
      }
      if (!c) {
        $(panel.id+"::children").insert(d);
      } else {
        c.insert({before: d});
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

// TODO: Um...  what's "object" for?
function handle_update(request, object) {
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
// TODO: think about changing our naming conventions so we don't need this.
function dc_split(str) {
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

function popup_node_menu(e)
{
  var target = Event.element(e);
  var pos = target.cumulativeOffset();
  $("menu::node").hawkNode = dc_split(target.parentNode.id)[1];
  $("menu::node").setStyle({left: pos.left+"px", top: pos.top+"px"}).show();
  Event.stop(e);
}

function node_menu_item_click(e)
{
  var state = "neutral";
  var c = $("node::" + $("menu::node").hawkNode);
  if (c.hasClassName("ns-active"))         state = "active";
  else if(c.hasClassName("ns-inactive"))  state = "inactive";
  else if(c.hasClassName("ns-error"))     state = "error";
  else if(c.hasClassName("ns-transient")) state = "transient";
  $("node::" + $("menu::node").hawkNode + "::menu").firstDescendant().src = "/images/spinner-16x16-" + state + ".gif";

  new Ajax.Request("/main/node_" + dc_split(Event.element(e).parentNode.id)[2], { parameters: "node=" + $("menu::node").hawkNode });
}

function init_menus() {

  menu = $(document.createElement("div")).writeAttribute("id", "menu::node").addClassName("menu").setStyle({display: "none"});
  // TODO: Localize!
  menu.update("<ul>" +
      '<li id="menu::node::online" class="menu-item"><a class="icon-start enabled" href="#" onclick="return false;">Online</a></li>\n' +
      '<li id="menu::node::standby" class="menu-item"><a class="icon-pause enabled" href="#" onclick="return false;">Standby</a></li>\n' +
      '<li id="menu::node::fence" class="menu-item"><a class="icon-kill enabled" href="#" onclick="return false;">Fence Node</a></li>\n' +
//      '<li id="menu::node::mark" class="menu-item"><a class="icon-mark-dead enabled" href="#" onclick="return false;">Mark Node Fenced</a></li>\n' +
    "</ul>");
  $("content").insert(menu);
  $("menu::node").hawkNode = null;

  $("menu::node::standby").firstDescendant().observe("click", node_menu_item_click);
  $("menu::node::online").firstDescendant().observe("click", node_menu_item_click);
  $("menu::node::fence").firstDescendant().observe("click", node_menu_item_click);
//  $("menu::node::mark").firstDescendant().observe("click", node_menu_item_click);

  document.observe('click', function(e) {
    $("menu::node").hide();
  });

  $$(".menu-link").each(function(e) {
    switch (dc_split(e.id)[0]) {
      case "node":
        e.addClassName("clickable");
        e.observe("click", popup_node_menu);
        e.firstDescendant().src = "/images/icons/properties.png";
        break;
    }
  });
}

function do_update() {
  setTimeout("new Ajax.Request('/main/status', { parameters: 'format=json', asynchronous: true, onComplete: handle_update });", 15000);
}

