// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

//= require_self

//= require module/basics
//= require module/help
//= require module/forms
//= require module/statusmatrix
//= require module/oplist
//= require module/attrlist
//= require module/wizattrlist
//= require module/recipientlist
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
//= require module/alerts
//= require module/locations
//= require module/colocations
//= require module/orders
//= require module/tickets
//= require module/roles
//= require module/users
//= require module/fencing
//= require module/profiles
//= require module/monitor
//= require module/status
//= require module/constraint
//= require module/reports
//= require module/batch
//= require module/location

$(function() {

  var resize = function() {
    var navHeight = $('.navbar-fixed-top').outerHeight();
    var footHeight = $('footer').show().outerHeight();
    var winHeight = $(window).outerHeight() - navHeight;
    var maxHeight = Math.max.apply(
      null,
      $('#middle, #rightbar').map(function() {
        return $(this).height('auto').outerHeight();
      }).get()
    );
    $('#middle, #rightbar').height(
      winHeight > maxHeight ? winHeight : maxHeight
    );
  };

  var createMutationObserver = function() {
    var target = document.querySelector('#middle');
    var observer = new MutationObserver(function(mutations) {
      observer.disconnect();
      resize();
      observer.observe(target, config);
    });
    var config = { childList: true, attributes: true, characterData: false, subtree: true };
    observer.observe(target, config);
  };

  $(window).on(
    'load resize',
    resize
  );

  $(window).on(
    'load',
    createMutationObserver
  );
});
