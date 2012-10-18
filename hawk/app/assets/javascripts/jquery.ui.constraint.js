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

/*
  chain is:

  [
    {
      resources: [ { id: "foo", action: "master" } ]
    },
    {
      resources: [
        { id: "bar", action: "master" },
        { id: "baz", action: "master" }
      ]
    }
  ]

  i.e. similar, but not identical to the set structure in the order
  model.  Differences:
    - Here, each resource always explicitly specifies an action (role)
    - multiple resources in a set are only appropriate for nonsequential
      sets.  Sequential sets must be broken out into individual resources
      so the relations appear correctly.
    - action is always called action, even if it's a role (see below)

  This is admittedly a slightly cumbersome implementation.

*/

// Note: the term action is used here (as in action of an order constraint), but
// this applies equally for roles for colocation constraints (i.e., just set
// options.actions = [ "Stopped", "Started", "Master", "Slave" ])

// TODO(should): do we care about passing anything back for dirty?

(function($) {
  $.widget("ui.constraint", {
    options: {
      resources: [],
      chain: [],
      actions: ["start", "promote", "demote", "stop"],
      imgroot: "/assets/",
      labels: {
        add: "Add",
        remove: "Remove",
        link: "Link set",
        cut: "Break set",
        swap: "Swap Resources",
        heading_add: "Add resource to constraint"
      },
      prefix: "",
      dirty: null
    },
    in_chain: {}, // temp, only valid during init

    // To be a valid constraint, there must be at least one relation,
    // and the last item in the chain must be a resource (or set).
    // This is enough of a test, because the implementation ensures
    // that there'll always be a dangling relation if there's only
    // one resource, or nothing at all if there's no resources.
    valid: function() {
      var self = this;
      if (self.element.find("tr.chain-rel").length > 0 &&
          !self.new_item_row.prev().hasClass("chain-rel")) {
        return true;
      } else {
        return false;
      }
    },

    _create: function() {
      var self = this;
      var e = self.element;
      e.addClass("ui-constraint");
      e.append($('<table cellpadding="0" cellspacing="0">' +
          '<tr><th class="label" colspan="2">' + escape_html(self.options.labels.heading_add) + ":</td></tr>" +
          "<tr>" +
            '<th colspan="2"><select><option></option></select></th>' +
            '<td><button type="button">' + escape_html(self.options.labels.add) + "</button></td>" +
          "</tr>" +
        "</table>"));
      self.new_item_select = e.find("select");
      self.new_item_row = $(e.find("tr")[0]);
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

      for (var i = 0; i < self.options.chain.length - 1; i++) {
        self._append_set(self.options.chain[i]);
        self._append_rel();
      }
      if (self.options.chain.length > 1) {
        self._append_set(self.options.chain[self.options.chain.length - 1]);
      }

      $.each(self.options.resources, function(i, n) {
        if (!self.in_chain[n]) {
          self.new_item_select.append($('<option value="' + escape_html(n) + '">' + escape_html(n) + "</option>"));
        }
      });
    },

    // appends rows based on set from chain
    _append_set: function(set) {
      var self = this;
      self.in_chain[set.resources[0].id] = true;
      if (set.resources.length == 1) {
        self._append_row(set.resources[0].id, set.resources[0].action);
        return;
      }
      self._append_row(set.resources[0].id, set.resources[0].action,
        "ui-corner-tl res set-t l", "ui-corner-tr res set-t r");
      for (var i = 1; i < set.resources.length - 1; i++) {
        self._append_cut();
        self.in_chain[set.resources[i].id] = true;
        self._append_row(set.resources[i].id, set.resources[i].action,
          "res set-m l", "res set-m r");
      }
      self._append_cut();
      self.in_chain[set.resources[set.resources.length - 1].id] = true;
      self._append_row(set.resources[set.resources.length - 1].id,
        set.resources[set.resources.length - 1].action,
        "ui-corner-bl res set-b l", "ui-corner-br res set-b r");
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

    _swap_text: function(a, b) {
      var t = a.text();
      a.text(b.text());
      b.text(t);
    },

    _swap_fields: function(a, b) {
      var t = a.val();
      a.val(b.val());
      b.val(t);
    },

    _swap: function(event) {
      var self = event.data;
      var row = $(this).parent().parent();
      if (!row.prev().hasClass("chain-res") || !row.next().hasClass("chain-res")) {
        // Do nothing if there's not a resource on either side of the relation
        // (i.e. it's a dangling relation)
        return;
      }

      var pr = row.prev();
      var nr = row.next();
      self._swap_fields(pr.find("input"), nr.find("input"));
      self._swap_fields(pr.find("select"), nr.find("select"));
      self._swap_text($(pr.find("span")[0]), $(nr.find("span")[0]));
      self._normalize_action(pr);
      self._normalize_action(nr);

      self._trigger("dirty", event, {});
    },

    _set_link_row: function() {
      var self = this;
      // Note: border: none, background none, makes it "smaller" than regular resource manipulation buttons
      var r = $('<tr class="chain-rel">' +
          '<td class="rel" colspan="2">' +
            '<input type="hidden" ' + self._field_name() + ' value="rel"/>' +
            '<img src="' + self.options.imgroot + 'arrow-down.png" alt="&darr;" /></td>' +
          '<td><button type="button" style="border: none; background: none;">' + self.options.labels.link + "</button></td>" +
          '<td><button type="button" style="border: none; background: none;">' + self.options.labels.swap + "</button></td>" +
        '</tr>');
      $(r.find("button")[0]).button({
        icons: {
          primary: "ui-icon-link"
        },
        text: false
      }).bind("click", self, self._set_link);
      $(r.find("button")[1]).button({
        icons: {
          primary: "ui-icon-arrow-2-n-s"
        },
        text: false
      }).bind("click", self, self._swap);
      return r;
    },

    _set_link: function(event) {
      var self = event.data;
      var row = $(this).parent().parent();
      if (!row.prev().hasClass("chain-res") || !row.next().hasClass("chain-res")) {
        // Do nothing if there's not a resource on either side of the relation
        // (i.e. it's a dangling relation)
        return;
      }
      row.fadeOut("fast", function() {

        // Previous item will always be either a set bottom (in which
        // case it becomes set mid), or a resource (in which case
        // it becomes set top).
        if ($(this).prev().children(":first").hasClass("set-b")) {
          self._to_set_m($(this).prev());
        } else {
          self._to_set_t($(this).prev());
        }

        // Next td will always be either a set top (in which case
        // it becomes set mid), or a resource (in which case it
        // becomes set bottom).
        if ($(this).next().children(":first").hasClass("set-t")) {
          self._to_set_m($(this).next());
        } else {
          self._to_set_b($(this).next());
        }

        var prev_row = $(this).prev();
        $(this).replaceWith(self._set_cut_row());
        self._normalize_action(prev_row);

        // If there's no relations, append the dangling relation
        if (!self.element.find("tr.chain-rel").length) {
          self._append_rel();
        }

        self._trigger("dirty", event, {});
      });
    },

    _set_cut_row: function() {
      var self = this;
      var r = $('<tr class="chain-set"><td class="set set-m" colspan="2">&nbsp;</td>' +
          '<td><button type="button" style="border: none; background: none;">' + self.options.labels.cut + "</button></td>" +
          '<td><button type="button" style="border: none; background: none;">' + self.options.labels.swap + "</button></td>" +
        '</tr>');
      $(r.find("button")[0]).button({
        icons: {
          primary: "ui-icon-scissors"
        },
        text: false
      }).bind("click", self, self._set_cut);
      $(r.find("button")[1]).button({
        icons: {
          primary: "ui-icon-arrow-2-n-s"
        },
        text: false
      }).bind("click", self, self._swap);
      return r;
    },

    _set_cut: function(event) {
      var self = event.data;
      $(this).parent().parent().fadeOut("fast", function() {

        // Previous item will always be either a set top (in which
        // case it becomes a resource), or a set mid (in which case
        // it becomes set bottom).
        self._set_t_to_res_or_b($(this).prev());

        // Next td will always be either a set bottom (in which case
        // it becomes a resource), or a set mid (in which case it
        // becomes set top).
        self._set_b_to_res_or_t($(this).next());

        $(this).replaceWith(self._set_link_row());

        // If there's a dangling relation, remove it
        if (self.new_item_row.prev().hasClass("chain-rel")) {
          self.new_item_row.prev().remove();
        }

        self._trigger("dirty", event, {});
      });
    },

    _normalize_action: function(row) {
      val = row.find("select").val();
      var r = row;
      while (r.prev().hasClass("chain-set")) {
        r = r.prev().prev();
        r.find("select").val(val);
      };
      r = row;
      while (r.next().hasClass("chain-set")) {
        r = r.next().next();
        r.find("select").val(val);
      }
    },

    _append_rel: function() {
      var self = this;
      var new_row = self._set_link_row();
      self.new_item_row.before(new_row);
      return new_row;
    },

    _append_cut: function() {
      var self = this;
      var new_row = self._set_cut_row();
      self.new_item_row.before(new_row);
      return new_row;
    },

    _field_name: function(n) {
      var self = this;
      n = self.options.prefix + "[]" + (n ? "[" + n + "]" : "");
      return 'id="' + n.replace(/]/g, "").replace(/\[/g, "_") + '" name="' + n + '"';
    },

    _append_row: function(res_id, action, class_l, class_r) {
      var self = this;

      var actions = "";
      $.each(self.options.actions, function(i, n) {
        actions += "<option" + (action == n ? ' selected="selected"' : "") + ">" + escape_html(n) + "</option>";
      });

      class_l = class_l || "ui-corner-left res l";
      class_r = class_r || "ui-corner-right res r";

      var new_row = $('<tr class="chain-res">' +
          '<td class="' + class_l + '"><input type="hidden" ' + self._field_name("id") + ' value="' + escape_field(res_id) + '"/>' +
            "<span>" + escape_html(res_id) + "</span></td>" +
          '<td class="' + class_r + '"><select ' + self._field_name("action") + "><option></option>" + actions + "</select></td>" +
          '<td><button type="button">' + self.options.labels.remove + "</button></td>" +
        "</tr>");
      new_row.find("select").change(function(event) {
        self._normalize_action($(this).parent().parent());
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
            // Remove subsequent cut row
            $(this).next().remove();
            // Make next resource row resource or set top
            self._set_b_to_res_or_t($(this).next());
          } else if ($(this).children(":first").hasClass("set-m")) {
            // Remove previous cut row
            $(this).prev().remove();
          } else if ($(this).children(":first").hasClass("set-b")) {
            // Remove previous cut row
            $(this).prev().remove();
            // Make previous resource row resource or set bottom
            self._set_t_to_res_or_b($(this).prev());
          } else {
            // Resource.  Remove previous relation, unless it's
            // the only relation (leaves one dangling)
            if ($(this).prev().hasClass("chain-rel") &&
                self.element.find("tr.chain-rel").length > 1) {
              $(this).prev().remove();
            }
          }

          // If this is the first resource, delete the subsequent
          // relation
          if ($(this).prev().length == 0 && $(this).next().hasClass("chain-rel")) {
            $(this).next().remove();
          }

          $(this).remove();

          // If there's any resources left, but no relations, append the dangling relation
          if (self.element.find("tr.chain-res").length && !self.element.find("tr.chain-rel").length) {
            self._append_rel();
          }

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

      if (self.new_item_row.prev().length &&
          !self.new_item_row.prev().hasClass("chain-rel")) {
        // Append relation if this isn't the first resource,
        // and there's not already a relation in place
        self._append_rel().effect("highlight", {}, 1000);
      }

      self._append_row(n).effect("highlight", {}, 1000);
      self.new_item_select.children("option[value='" + n + "']").remove();
      self.new_item_select.val("");

      if (!self.element.find("tr.chain-rel").length) {
        // Append relation if there's none already present
        // (i.e. leave dangling relation when first resource
        // added to chain).
        self._append_rel().effect("highlight", {}, 1000);
      }

      self._trigger("dirty", event, {});
    }
  });
})(jQuery);

