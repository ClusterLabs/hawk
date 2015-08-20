// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

//= require_self

//= require module/basics
//= require module/help
//= require module/forms
//= require module/modals
//= require module/wizards
//= require module/nodes
//= require module/resources
//= require module/constraints
//= require module/primitives
//= require module/templates
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
//= require module/attrlist
//= require module/constraint
//= require module/explorer

$(function() {
  $(window).on(
    'load resize',
    function() {
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
    }
  );
});
