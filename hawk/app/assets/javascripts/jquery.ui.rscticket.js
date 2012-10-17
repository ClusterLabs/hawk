//======================================================================
//                        HA Web Konsole (Hawk)
// --------------------------------------------------------------------
//            A web-based GUI for managing and monitoring the
//          Pacemaker High-Availability cluster resource manager
//
// Copyright (c) 2012 Novell Inc., All Rights Reserved.
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
// along with this program; if not, see <http://www.gnu.org/licenses/>.
//
//======================================================================

// Similar to, but simpler than, ui.constraint; just does a set of
// resources with independent roles.  Named ui.rscticket because
// it's really only applicable as a resource set as used in ticket
// contraints, it can't replace the set part of a colocation or
// order contraint without becoming stupidly complex.
//
// Semantic differences from ui.constraint:
// - set instead of chain
// - role(s) instead of action(s)
//
// TODO(should): do we care about passing anything back for dirty?

(function($) {
  $.widget("ui.rscticket", {
    options: {
      resources: [],
      set: [],   // [ {id: "foo", role: "Started" }, { ... } ]
      roles: ["Started", "Master", "Slave", "Stopped"],
      imgroot: "/images/",
      labels: {
        add: "Add",
        remove: "Remove",
        heading_add: "Add resource to constraint",
        ticket_id: "Ticket ID"
      },
      prefix: "",
      ticket_fn: "", // ticket id field name
      dirty: null
    },
    in_chain: {}, // temp, only valid during init

    // To be a valid constraint, there must be at least one resource.
    valid: function() {
      var self = this;
      return this.element.find("tr.chain-res").length > 0;
    },

    _create: function() {
      var self = this;
      var e = self.element;
      e.addClass("ui-rscticket");
      e.append($('<table cellpadding="0" cellspacing="0">' +
          '<tr>' +
            '<td colspan="2" class="ui-corner-all res">' + escape_html(self.options.labels.ticket_id) + ": " +
              '<input type="text" id="' +
              self.options.ticket_fn.replace(/]/g, "").replace(/\[/g, "_") + '" name="' +
              self.options.ticket_fn + '"/></td>' +
          '</tr>' +
          '<tr><td class="rel" colspan="2">' +
            '<img src="' + self.options.imgroot + 'arrow-down.png" alt="&darr;" /></td>' +
          '</td></tr>' +
          '<tr><th class="label" colspan="2">' + escape_html(self.options.labels.heading_add) + ":</td></tr>" +
          "<tr>" +
            '<th colspan="2"><select><option></option></select></th>' +
            '<td><button type="button">' + escape_html(self.options.labels.add) + "</button></td>" +
          "</tr>" +
        "</table>"));
      self.new_item_select = e.find("select");
      self.new_item_row = $(e.find("tr")[2]);
      self.new_item_add = e.find("button");
      self.new_item_add.button({
        icons: {
          primary: "ui-icon-plus"
        },
        text: false,
        disabled: true
      }).click(function(event) {
        self._add_item(event);
      });
      self.new_item_select.bind("keyup change", function() {
        self.new_item_add.button("option", "disabled", $(this).val() ? false : true);
      })
    },

    _init: function() {
      var self = this;

      // TODO(should): remove anything that already exists (only necessary if
      // this gets re-used after initial setup).
      self.new_item_select.children().remove();
      self.new_item_select.append($("<option></option>"));

      if (self.options.set.length > 0) {
        var set = self.options.set;
        self.in_chain[set[0].id] = true;
        if (set.length == 1) {
          self._append_row(set[0].id, set[0].role);
        } else {
          self._append_row(set[0].id, set[0].role,
            "ui-corner-tl res set-t l", "ui-corner-tr res set-t r");
          for (var i = 1; i < set.length - 1; i++) {
            self.in_chain[set[i].id] = true;
            self._append_row(set[i].id, set[i].role,
              "res set-m l", "res set-m r");
          }
          self.in_chain[set[set.length - 1].id] = true;
          self._append_row(set[set.length - 1].id, set[set.length - 1].role,
            "ui-corner-bl res set-b l", "ui-corner-br res set-b r");
        }
      }

      $.each(self.options.resources, function(i, n) {
        if (!self.in_chain[n]) {
          self.new_item_select.append($('<option value="' + escape_html(n) + '">' + escape_html(n) + "</option>"));
        }
      });
    },

    _to_res: function(row) {
      $(row.children()[0]).attr("class", "ui-corner-left res l");
      $(row.children()[1]).attr("class", "ui-corner-right res r");
    },

    _to_set_t: function(row) {
      $(row.children()[0]).attr("class", "ui-corner-tl res set-t l");
      $(row.children()[1]).attr("class", "ui-corner-tr res set-t r");
    },

    _to_set_m: function(row) {
      $(row.children()[0]).attr("class", "res set-m l");
      $(row.children()[1]).attr("class", "res set-m r");
    },

    _to_set_b: function(row) {
      $(row.children()[0]).attr("class", "ui-corner-bl res set-b l");
      $(row.children()[1]).attr("class", "ui-corner-br res set-b r");
    },

    _set_t_to_res_or_b: function(row) {
      if (row.children(":first").hasClass("set-t")) {
        this._to_res(row);
      } else {
        this._to_set_b(row);
      }
    },

    _set_b_to_res_or_t: function(row) {
      if (row.children(":first").hasClass("set-b")) {
        this._to_res(row);
      } else {
        this._to_set_t(row);
      }
    },

    _field_name: function(n) {
      var self = this;
      n = self.options.prefix + "[]" + (n ? "[" + n + "]" : "");
      return 'id="' + n.replace(/]/g, "").replace(/\[/g, "_") + '" name="' + n + '"';
    },

    _append_row: function(res_id, role, class_l, class_r) {
      var self = this;

      var roles = "";
      $.each(self.options.roles, function(i, n) {
        roles += "<option" + (role == n ? ' selected="selected"' : "") + ">" + escape_html(n) + "</option>";
      });

      class_l = class_l || "ui-corner-left res l";
      class_r = class_r || "ui-corner-right res r";

      var new_row = $('<tr class="chain-res">' +
          '<td class="' + class_l + '"><input type="hidden" ' + self._field_name("id") + ' value="' + escape_field(res_id) + '"/>' +
            "<span>" + escape_html(res_id) + "</span></td>" +
          '<td class="' + class_r + '"><select ' + self._field_name("role") + "><option></option>" + roles + "</select></td>" +
          '<td><button type="button">' + self.options.labels.remove + "</button></td>" +
        "</tr>");
      new_row.find("select").change(function(event) {
        self._trigger("dirty", event, {});
      });
      new_row.find("button").button({
        icons: {
          primary: "ui-icon-minus"
        },
        text: false
      }).click(function(event) {
        $(this).parent().parent().fadeOut("fast", function() {
          var deleted_res = $(this).children(":first").text();

          if ($(this).children(":first").hasClass("set-t")) {
            // Make next resource row resource or set top
            self._set_b_to_res_or_t($(this).next());
          } else if ($(this).children(":first").hasClass("set-b")) {
            // Make previous resource row resource or set bottom
            self._set_t_to_res_or_b($(this).prev());
          }

          $(this).remove();

          self._trigger("dirty", event, {} );

          // Inject deleted resource back into resource list
          var new_option = "<option value='" + escape_field(deleted_res) + "'>" + escape_html(deleted_res) + "</option>";
          var options = self.new_item_select[0].options;
          var i = 0;
          for (i = 0; i < options.length; i++)
          {
            if (options[i].value == deleted_res) {
              // It's possible to click a fading button fast enough to insert dupes...
              return;
            }
            if (options[i].value > deleted_res) break;
          }
          if (i >= options.length) {
            // Last item
            self.new_item_select.append(new_option);
          } else {
            self.new_item_select.children("option:eq(" + i + ")").before(new_option);
          }

        });

      });

      self.new_item_row.before(new_row);

      return new_row;
    },

    _add_item: function(event) {
      var self = this;
      var n = self.new_item_select.val();
      if (!n) return;

      var a = "";
      var l = null;
      var r = null;
      var p = self.new_item_row.prev();
      if (p.hasClass("chain-res")) {
        if (p.children(":first").hasClass("set-b")) {
          self._to_set_m(p);
        } else {
          self._to_set_t(p);
        }
        l = "ui-corner-bl res set-b l";
        r = "ui-corner-br res set-b r";
      }
      self._append_row(n, a, l, r).effect("highlight", {}, 1000);
      self.new_item_select.children("option[value='" + n + "']").remove();
      self.new_item_select.val("");

      self._trigger("dirty", event, {});
    }
  });
})(jQuery);

