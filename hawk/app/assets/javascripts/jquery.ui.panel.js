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

(function($) {
  $.widget("ui.panel", {
    options: {
      menu_click: null,
      menu_href:  "",
      menu_icon:  "",
      menu_alt:   "",
      menu_id:    null,
      label:      "",
      body:       null,
      open:       false
    },
    _create: function() {
      var e = this.element;
      e.addClass("ui-panel ui-corner-all");
      var c = e.children().remove();  // preserve existing children
      e.append($(
        '<div class="clickable">' +
          '<div class="tri-closed"></div>' +
          '<a><img class="action-icon" alt="" /></a><span></span>' +
        "</div>" +
        '<div style="display: none;" class="closed"></div>'));
      this.header     = e.children(":first");
      this.expander   = e.find(".tri-closed");
      this.menu_link  = e.find("a");
      this.menu_img   = e.find("img");
      this.label      = e.find("span");
      this.body       = e.children(":last");
      this.body.append(c);
      var self = this;
      this.header.click(function() {
        self.toggle();
      });
    },
    _init: function() {
      var e = this.element;
      this.menu_img.attr("src", this.options.menu_icon);
      this.menu_img.attr("alt", this.options.menu_alt);
      this.menu_img.attr("title", this.options.menu_alt);
      if (this.options.menu_href) {
        this.menu_link.attr("href", this.options.menu_href);
        this.menu_link.click(function(event) {
          // TODO(should): fix this messy event canceling to stop the
          // panel expanding/contracting when menu clicked
          event.stopPropagation();
        });
      }
      if (this.options.menu_click) {
        this.menu_link.click(this.options.menu_click);
      }
      if (this.options.menu_id) {
        this.menu_link.attr("id", this.options.menu_id);
      }
      this.set_label(this.options.label);
      if (this.options.body) {
        this.body.append(this.options.body);
      }
      if (this.options.open) {
        // Instant show
        this.body.removeClass("closed").show();
        this.expander.removeClass("tri-closed").addClass("tri-open");
      }
    },
    destroy: function() {
      $.Widget.prototype.destroy.apply(this, arguments); // default destroy
    },
    expand: function() {
      if (!this.body.hasClass("closed")) return;  // Necessary in case client calls explicitly
      this.body.removeClass("closed").show("blind", {}, "fast");
      this.expander.removeClass("tri-closed").addClass("tri-open");
    },
    collapse: function() {
      if (this.body.hasClass("closed")) return;   // Necessary in case client calls explicitly
      this.body.addClass("closed").hide("blind", {}, "fast");
      this.expander.removeClass("tri-open").addClass("tri-closed");
    },
    toggle: function() {
      if (this.body.hasClass("closed")) {
        this.expand();
      } else {
        this.collapse();
      }
    },
    set_label: function(label) {
      this.label.html(label);
    },
    set_class: function(className) {
      this.element.attr("class", "ui-panel ui-corner-all " + className);
    },
    body_element: function() {
      return this.body;
    }
  });
})(jQuery);

