// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

//= require_self

$(function() {
  if ($("#session_username").val() == "") {
    $("#session_username").focus();
  } else {
    if ($("#session_password").val() == "") {
      $("#session_password").focus();
    }
  }
});
