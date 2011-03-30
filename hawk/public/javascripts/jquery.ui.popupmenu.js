//======================================================================
//                        HA Web Konsole (Hawk)
// --------------------------------------------------------------------
//            A web-based GUI for managing and monitoring the
//          Pacemaker High-Availability cluster resource manager
//
// Copyright (c) 2011 Novell Inc., Tim Serong <tserong@novell.com>
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

//
// The intuitive, jQuery way, would be to create a popup menu on the
// element you want clicked to activate the menu.  However, for Hawk's
// status page, this means a separate popup menu for every resource,
// when actually the menu items are all more or less the same.  So
// instead we create a popup menu on a div (which just turns the div
// into the menu), and separately bind the targets to click on to only
// a couple of popup menus, with dynamically shown/hidden menu items.
//

(function($) {
  $.widget("ui.popupmenu", {
    options: {
      items: [],
      iconroot: ""
    },
    target: null,
    _create: function() {
      var self = this;
      var e = self.element;
      e.addClass("ui-popupmenu").hide();
      e.append($("<ul></ul>"));
      self.list = $(e.children(":first"));
      $(document).click(function() {
        self._hide();
      });
    },
    _init: function() {
      var self = this;
      self.list.children().remove();
      $.each(self.options.items, function() {
        var item = this;
        if (item.separator) {
          self.list.append($('<li class="menu-separator"></li>'));
        } else {
          // Need href="#" for hover style to work in IE.
          self.list.append($('<li class="menu-item"><a class="enabled" style="background-image: url(' +
            self.options.iconroot + item.icon + ');" href="#">' +
            escape_html(item.label) + "</a></li>"));
          self.list.children(":last").children(":first").click(function() {
            self._hide();
            if (item.click) { item.click(self.target); }
            return false; // Don't try to follow the link
          });
        }
      });
    },
    _hide: function() {
      this.element.hide();
    },
    // Call popup() from the click event handler on the A element you
    // want to use to activate the popup.  Bases position on the
    // first child of the A element (i.e. works with <a><img/></a>).
    // 'target' must be the jQuery object for the A element.
    // 'hide_items' is an array of indices of menu items to hide.
    popup: function(target, hide_items) {
      var pos = target.children(":first").offset();
      $(this.list.children().show());
      if (hide_items) {
        for (var i = 0; i < hide_items.length; i++) {
          $(this.list.children()[hide_items[i]]).hide();
        }
      }
      this.target = target;
      this.element.css({left: pos.left+"px", top: pos.top+"px"}).show();
      return false; // Stop propagation
    }
  });
})(jQuery);

