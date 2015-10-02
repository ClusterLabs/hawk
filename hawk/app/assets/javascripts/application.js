// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

//= require_self

//= require module/basics
//= require module/help
//= require module/forms
//= require module/oplist
//= require module/attrlist
//= require module/wizattrlist
//= require module/modals
//= require module/wizards
//= require module/nodes
//= require module/resources
//= require module/constraints
//= require module/primitives
//= require module/masters
//= require module/clones
//= require module/groups
//= require module/tags
//= require module/locations
//= require module/colocations
//= require module/orders
//= require module/tickets
//= require module/roles
//= require module/users
//= require module/profiles
//= require module/monitor
//= require module/status
//= require module/constraint
//= require module/reports
//= require module/simulator
//= require module/location

$(function() {
  var resize = function() {
    console.log('resize');

    var navHeight = $('.navbar-fixed-top').outerHeight();
    var footHeight = $('footer').outerHeight();

    var winHeight = $(window).outerHeight() - navHeight - footHeight;

    var maxHeight = Math.max.apply(
      null,
      $('#sidebar, #middle, #rightbar').map(function() {
        return $(this).height('auto').outerHeight();
      }).get()
    );

    $('#sidebar, #middle, #rightbar').height(
      winHeight > maxHeight ? winHeight : maxHeight
    );
  };

  //$(window).on(
  //  'load resize',
  //  resize
  //);

  // TODO(must): This is just a partial footer fix
  $('#middle > .container-fluid').on(
    'post-body.bs.table shown.bs.collapse',
    resize
  );
});
