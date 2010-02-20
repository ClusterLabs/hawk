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
          // TODO: HTML-safe?
          d.update('<div class="clickable" onclick="toggle_collapse(\'' + item.id + '\');">' +
            '<div id="' + item.id + '::button" class="tri-' + (item.open ? 'open' : 'closed') + '"></div><span id="' + item.id + '::label"></span></div>' +
            '<div id="' + item.id + '::children"' + (item.open ? ' style="display: none;" class="closed"' : '') + '</div>');
        } else {
          d.update('<span id="' + item.id + '::label"></span>');
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

function do_update() {
  setTimeout("new Ajax.Request('/main/status', { parameters: 'format=json', asynchronous: true, onComplete: handle_update });", 15000);
}

