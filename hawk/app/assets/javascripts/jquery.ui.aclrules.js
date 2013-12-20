//======================================================================
//                        HA Web Konsole (Hawk)
// --------------------------------------------------------------------
//            A web-based GUI for managing and monitoring the
//          Pacemaker High-Availability cluster resource manager
//
// Copyright (c) 2014 SUSE LLC, All Rights Reserved.
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

(function($) {
  $.widget("ui.aclrules", {

    options: {
      rules: [],
      labels: {
        add: "Add",
        remove: "Remove",
        heading_right: "Right",
        heading_xpath: "XPath",
        heading_tag: "Tag",
        heading_ref: "Ref",
        heading_attr: "Attribute"
      },
      prefix: "",
      dirty: null
    },
    rights: ["read", "write", "deny"],

    _create: function() {
      // Can't use real 'this' inside $.each(), or in event handlers,
      // so use 'self' throughout for "consistency".
      var self = this;
      var e = self.element;
      // TODO(should): add ui-widget class (but style it properly first; fonts don't match the rest of Hawk yet)
      e.addClass("ui-aclrules");
      e.append($("<table><tr>" +
          '<th class="label" style="padding-top: 1em;">' + escape_html(self.options.labels.heading_right) + "</th>" +
          '<th class="label" style="padding-top: 1em;">' + escape_html(self.options.labels.heading_xpath) + "</th>" +
          '<th class="label" style="padding-top: 1em;">' + escape_html(self.options.labels.heading_tag) + "</th>" +
          '<th class="label" style="padding-top: 1em;">' + escape_html(self.options.labels.heading_ref) + "</th>" +
          '<th class="label" style="padding-top: 1em;">' + escape_html(self.options.labels.heading_attr) + "</th>" +
        "</tr><tr>" +
          '<td>' + self._right_select("", true) + '</td>' +
          '<td class="xpath">' + self._input_field("xpath") + '</td> ' +
          '<td class="tag">' + self._input_field("tag") + '</td> ' +
          '<td class="ref">' + self._input_field("ref") + '</td> ' +
          '<td class="attr">' + self._input_field("attribute") + '</td> ' +
          '<td><button type="button">' + escape_html(self.options.labels.add) + "</button></td>" +
        "</tr></table>"));
      self.new_rule_row = $(e.find("tr")[1]);
      self.new_rule_right = e.find("select");
      self.new_rule_xpath = e.find("td.xpath input");
      self.new_rule_tag = e.find("td.tag input");
      self.new_rule_ref = e.find("td.ref input");
      self.new_rule_attr = e.find("td.attr input");
      self.new_rule_add = e.find("button");
      self.new_rule_add.button({
        icons: {
          primary: "ui-icon-plus"
        },
        text: false,
        disabled: true
      }).click(function(event) {
        self._add_rule(event);
      });;
      self.new_rule_row.find("input, select").bind("keyup change", function(event) {
        self.new_rule_add.button("option", "disabled", self._valid_rule(self.new_rule_row) ? false : true);
        self._trigger("dirty", event);
      });
    },

    _init: function() {
      var self = this;
      self.element.find(".aclrules-del").remove();
      $.each(self.options.rules, function(i, r) {
        self._insert_row(r.right, r.xpath, r.tag, r.ref, r.attribute);
      });
    },

    _field_name: function(n) {
      var self = this;
      n = self.options.prefix + "[]" + (n ? "[" + n + "]" : "");
      return 'id="' + n.replace(/]/g, "").replace(/\[/g, "_") + '" name="' + n + '"';
    },

    _right_select: function(v, blank) {
      var self = this;
      var select = "<select " + self._field_name("right") + ">";
      if (blank) select += "<option></option>";
      $.each(self.rights, function() {
        var r = this.toString();
        select += "<option" + (v == r ? ' selected="selected"' : "") + ">" + escape_html(r) + "</option>";
      });
      select += "</select>";
      return select;
    },

    _input_field: function(n, v) {
      var self = this;
      return '<input type="text" ' + self._field_name(n) + ' value="' + escape_html(v ? v : "") + '" />';
    },

    _insert_row: function(right, xpath, tag, ref, attr) {
      var self = this;
      var new_row = $(
        '<tr class="aclrules-del">' +
          '<td>' + self._right_select(right) + '</td>' +
          '<td class="xpath">' + self._input_field("xpath", xpath) + '</td> ' +
          '<td class="tag">' + self._input_field("tag", tag) + '</td> ' +
          '<td class="ref">' + self._input_field("ref", ref) + '</td> ' +
          '<td class="attr">' + self._input_field("attribute", attr) + '</td> ' +
          '<td><button type="button">' + self.options.labels.remove + "</button></td>" +
        "</tr>");
      new_row.find("button").button({
        icons: {
          primary: "ui-icon-minus"
        },
        text: false,
        disabled: false
      }).click(function(event) {
        $(this).parent().parent().fadeOut("fast", function() {
          var deleted_name = $(this).children(":first").text();
          $(this).remove();
          self._trigger("dirty", event );
        });
      });;
      new_row.find("input, select").bind("keyup change", function(event) {
        self._trigger("dirty", event);
      });

      self.new_rule_row.before(new_row);

      self._scroll_into_view();

      return new_row;
    },

    _add_rule: function(event) {
      var self = this;
      if (!self._valid_rule(self.new_rule_row)) return;
      self._insert_row(self.new_rule_right.val(), $.trim(self.new_rule_xpath.val()), $.trim(self.new_rule_tag.val()),
        $.trim(self.new_rule_ref.val()), $.trim(self.new_rule_attr.val())).effect("highlight", {}, 1000);
      self._trigger("dirty", event);
      self.new_rule_right.val("");
      self.new_rule_xpath.val("");
      self.new_rule_tag.val("");
      self.new_rule_ref.val("");
      self.new_rule_attr.val("");
    },

    _scroll_into_view: function() {
      this.element.scrollTop(this.element.find("table tr:last").position().top);
    },

    _valid_rule: function(row) {
      var self = this;
      var right = row.find("select").val();
      var xpath = $.trim(row.find("td.xpath input").val());
      var tag = $.trim(row.find("td.tag input").val());
      var ref = $.trim(row.find("td.ref input").val());
      var attr = $.trim(row.find("td.attr input").val());
      if (right && xpath && !tag && !ref) return true;
      if (right && !xpath && (tag || ref)) return true;
      return false;
    },

    _empty_rule: function(row) {
      var self = this;
      var right = row.find("select").val();
      var xpath = $.trim(row.find("td.xpath input").val());
      var tag = $.trim(row.find("td.tag input").val());
      var ref = $.trim(row.find("td.ref input").val());
      var attr = $.trim(row.find("td.attr input").val());
      return (!right && !xpath && !tag && !ref && !attr);
    },

    // Returns a hash (same format as set_attrs), for
    // all values currently present in the attrlist
    val: function() {
      var v = {};
      this.element.find(".attrlist-del").each(function() {
        var f = $(this).children("td.value").children(":last");
        var n = f[0].name.match(/.*\[([^\]]+)\]$/)[1];
        v[n] = f[0].type == "checkbox" ? f[0].checked : f.val();
      });
      // Also grab the new attribute in the current '+' row, if any
      var f = this.new_attr_td.children(":last");
      if (f[0].name) {
        var n = f[0].name.match(/.*\[([^\]]+)\]$/)[1];
        v[n] = f[0].type == "checkbox" ? f[0].checked : f.val();
      }
      return v;
    },

    valid: function() {
      var self = this;
      var valid = true;

      var rule_rows = self.element.find(".aclrules-del");
      var new_rule_valid = self._valid_rule(self.new_rule_row);
      var new_rule_empty = self._empty_rule(self.new_rule_row);

      // If there's no rule rows present, we need at least the *new* rule
      // row to be valid as that gives us one valid rule.
      if (rule_rows.length == 0 && !new_rule_valid) {
        valid = false;
      }

      // If there are rule rows present, make sure they're all valid.
      rule_rows.each(function() {
        if (!self._valid_rule($(this))) {
          valid = false;
          return false;
        }
      });

      // Finally, make sure the new rule row is either valid or empty
      if (!new_rule_valid && !new_rule_empty) {
        valid = false;
      }
      return valid;
    },

    has_rules: function() {
      var self = this;
      return self.element.find(".aclrules-del").length > 0;
    }

  });
})(jQuery);

