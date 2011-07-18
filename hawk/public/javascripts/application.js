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

// Globally useful utility functions only in here

function escape_html(str) {
  return $("<div/>").text(str).html();
}

function escape_field(s) {
  return escape_html(s).replace(/"/g, "&quot;").replace(/'/g, "&#39;");
}

$(function() {
  // Always initialize dialog (it's in the main layout after all...)
  $("#dialog").dialog({
    resizable:      false,
    width:          "30em",
    draggable:      false,
    modal:          true,
    autoOpen:       false,
    closeOnEscape:  true
  });
});

// Note: /main/gettext?format=js must be included to use this
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

// Rails 2.3.11 fixes a CSRF vulnerability, which requires us to
// include a CSRF token with every AJAX request.  For details see:
// http://jasoncodes.com/posts/rails-csrf-vulnerability
function CSRFProtection(xhr) {
  var token = $('meta[name="csrf-token"]').attr("content");
  if (token) xhr.setRequestHeader("X-CSRF-Token", token);
}
if ("ajaxPrefilter" in $) {
  $.ajaxPrefilter(function(options, originalOptions, xhr) { CSRFProtection(xhr); });
} else {
  $(document).ajaxSend(function(e, xhr) { CSRFProtection(xhr); });
}

jQuery.fn.submitWithAjax = function() {
  this.submit(function() {
    $.post(this.action, $(this).serialize(), null, "script");
    return false;
  })
  return this;
};

