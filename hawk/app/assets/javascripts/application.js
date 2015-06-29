//======================================================================
//                        HA Web Konsole (Hawk)
// --------------------------------------------------------------------
//            A web-based GUI for managing and monitoring the
//          Pacemaker High-Availability cluster resource manager
//
// Copyright (c) 2009-2013 SUSE LLC, All Rights Reserved.
//
// Author: Tim Serong <tserong@suse.com>
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

//= require_self

//= require module/basics
//= require module/help
//= require module/forms
//= require module/modals
//= require module/wizards
//= require module/nodes
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
