//======================================================================
//                        HA Web Konsole (Hawk)
// --------------------------------------------------------------------
//            A web-based GUI for managing and monitoring the
//          Pacemaker High-Availability cluster resource manager
//
// Copyright (c) 2011-2013 SUSE LLC, All Rights Reserved.
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
  $.widget("ui.expression", {
    options: {
      exprs: [],
      labels: {
        add: "Add",
        remove: "Remove"
      },
      prefix: "",
      dirty: null
    },

    _create: function() {
      var self = this;
      var e = self.element;
      e.addClass("ui-expression");
      e.append($(
        "<table>" +
          "<tr>" +
            '<td colspan="4">' + self._select("", [
                {k:""},
                {k:"uname", v:"#uname"},
                {k:"attr-val", v:"[attribute] = [value]"},
                {k:"attr-def", v:"[attribute] defined"} ]) +
            "</td>" +
            '<td><button type="button">' + escape_html(self.options.labels.add) + "</button></td>" +
          "</tr>" +
        "</table>"));
      self.new_expr_row = $(e.find("tr")[0]);
      self.new_expr_select = e.find("select");
      self.new_expr_add = e.find("button");
      self.new_expr_add.button({
        icons: {
          primary: "ui-icon-plus"
        },
        text: false,
        disabled: true
      }).click(function(event) {
        self._add_expr(event);
        self._trigger("dirty", event, {} );
      });
      self.new_expr_select.change(function() {
        self.new_expr_add.button("option", "disabled", $(this).val() ? false : true);
      });
    },

    _init: function() {
      var self = this;
      self.element.find(".exprlist-del").remove();
      self.new_expr_select.val("");
      $.each(self.options.exprs, function() {
        if (this.operation == "defined" || this.operation == "not_defined") {
          self._append_row(self._row_attr_def(this));
        } else {
          self._append_row(self._row_attr_val(this));
        }
      });
    },

    // Note: Surprisingly similar to function in ui.constraint.js
    _field_name: function(n) {
      var self = this;
      n = self.options.prefix + "[][" + n + "]";
      return 'id="' + n.replace(/]/g, "").replace(/\[/g, "_") + '" name="' + n + '"';
    },

    // Note: Surprisingly similar to function in ui.location.js
    _select: function(idn, opts, value, className) {
      var s = "<select " + (idn ? idn : "") + (className ? ' class="' + className + '"' : "") + ">";
      $.each(opts, function() {
        s += '<option value="' + escape_field(this.k) + '"' +
          (this.k == value ? ' selected="selected"' : "") + ">" + ( this.v ? this.v : this.k ) + "</option>";
      });
      s += "</select>";
      return s;
    },

    _remove_row: function(event) {
      var self = event.data;
      $(this).parent().parent().fadeOut("fast", function() {
        $(this).remove();
        self._trigger("dirty", event, {} );
      });
    },

    _row_attr_val: function(expr) {
      var self = this;
      var attr  = (expr ? expr.attribute : "") || "";
      var op    = (expr ? expr.operation : "") || "";
      var value = (expr ? expr.value : "") || "";
      var type  = (expr ? expr.type : "") || "";
      return $(
        '<tr class="expr">' +
          '<td><input class="req" ' + self._field_name("attribute") + ' type="text" value="' + escape_field(attr) + '"></td>' +
          '<td>' + self._select(self._field_name("operation"), [
              {k:"eq", v:"="},
              {k:"ne", v:"&ne;"},
              {k:"lt", v:"&lt;"},
              {k:"lte", v:"&le;"},
              {k:"gte", v:"&ge;"},
              {k:"gt", v:"&gt;"} ], op, "req") +
          "</td>" +
          '<td><input class="req" ' + self._field_name("value") + ' type="text" value="' + escape_field(value) + '"></td>' +
          '<td>(' + self._select(self._field_name("type"), [
              {k:""},
              {k:"string"},
              {k:"integer"},
              {k:"version"} ], type) + ")" +
          "</td>" +
          '<td class="button"><button type="button">' + self.options.labels.remove + "</button></td>" +
        "</tr>"
      );
    },

    _row_attr_def: function(expr) {
      var self = this;
      var attr  = (expr ? expr.attribute : "") || "";
      var op    = (expr ? expr.operation : "") || "";
      return $(
        '<tr class="expr">' +
          '<td><input class="req" ' + self._field_name("attribute") + ' type="text" value="' + escape_field(attr) + '"></td>' +
          '<td colspan="3">' + self._select(self._field_name("operation"), [
            {k:"defined", v:"is defined"},
            {k:"not_defined", v:"is not defined"} ], op, "req") +
            '<input type="hidden" ' + self._field_name("value") + ' value=""/>' +
            '<input type="hidden" ' + self._field_name("type") + ' value=""/>' +
          "</td>" +
          '<td class="button"><button type="button">' + self.options.labels.remove + "</button></td>" +
        "</tr>"
      );
    },

    _append_row: function(new_row) {
      var self = this;
      new_row.find("button").button({
        icons: {
          primary: "ui-icon-minus"
        },
        text: false
      }).bind("click", self, self._remove_row);
      new_row.find("input[type=text]").bind("keyup change", function(event) {
        self._trigger("dirty", event, {});
      }).blur(function(event) {
        var v = $.trim(this.value);
        if (v != this.value) {
          this.value = v;
          self._trigger("dirty", event, {});
        }
      });
      new_row.find("select").change(function(event) {
        self._trigger("dirty", event, {});
      });
      self.new_expr_row.before(new_row);
      return new_row;
    },

    _add_expr: function() {
      var self = this;
      switch (self.new_expr_select.val()) {
        case "uname":
          var r = self._append_row(self._row_attr_val());
          $(r.find("input")[0]).val("#uname");
          r.effect("highlight", {}, 1000);
          r.find("input")[1].focus();
          break;
        case "attr-val":
          self._append_row(self._row_attr_val()).effect("highlight", {}, 1000).find("input")[0].focus();
          break;
        case "attr-def":
          self._append_row(self._row_attr_def()).effect("highlight", {}, 1000).find("input")[0].focus();
          break;
      }
      self.new_expr_select.val("");
    }
  });
})(jQuery);

