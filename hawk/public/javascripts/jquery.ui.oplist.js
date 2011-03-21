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

// TODO(must): keypress_hack for new_op_select
// TODO(must): field for dirty event?

(function($) {
  $.widget("ui.oplist", {

    options: {
      all_ops: {},
      set_ops: {},
      labels: {
        add: "Add",
        edit: "Edit",
        remove: "Remove"
      },
      prefix: "",
      dirty: null
    },

    _create: function() {
      var self = this;
      var e = self.element;
      // TODO(should): add ui-widget class (but style it properly first; fonts don't match the rest of Hawk yet)
      e.addClass("ui-oplist");
      e.append($("<table><tr>" +
        "<th><select><option></option></select></th>" +
        '<td class="value"></td>' +
        '<td class="button"></td>' +
        '<td class="button"><button type="button">' + escape_html(self.options.labels.add) + "</button></td>" +
        "</tr></table>"));
      self.new_op_row = $(e.find("tr")[0]);
      self.new_op_select = e.find("select");
      self.new_op_td = $(e.find("td")[0]);
      self.new_op_add = e.find("button");
      self.new_op_add.button({
        icons: {
          primary: "ui-icon-plus"
        },
        text: false,
        disabled: true
      }).click(function(event) {
        self._add_op(event);
      });;
      self.new_op_select.change(function() {
        self._init_new_op();
      });
    },

    _init: function() {
      var self = this;

      self.new_op_select.children().remove();
      self.new_op_select.append($("<option></option>"));

      self._sort_ops();

      $.each(self.ops, function(i, n) {
        if (n in self.options.set_ops) {
          self._insert_row(n, self.options.set_ops[n]);
        } else {
          self.new_op_select.append($('<option value="' + escape_field(n) + '">' + escape_html(n) + "</option>"));
        }
      });

      self._init_new_op();
    },

    _sort_ops: function() {
      this.ops = [];
      for (var n in this.options.all_ops) {
        this.ops.push(n);
      }
      this.ops.sort();
    },

    _init_new_op: function() {
      var n = this.new_op_select.val();
      this.new_op_add.button("option", "disabled", n ? false : true);
      if (n) {
        this.new_op_td.text(this._op_value_string(n, this.options.all_ops[n]));
      } else {
        this.new_op_td.text("");
      }
      if (this.new_op_select[0].options.length == 1) {
        this.new_op_select.attr("disabled", "disabled");
      } else {
        this.new_op_select.removeAttr("disabled");
      }
    },

    _op_value_string: function(n, op) {
      var v = "timeout: " + op.timeout;
      if (n == "monitor") {
        v += " interval: " + op.interval;
      }
      return v;
    },

    _op_fields: function(n, op) {
      var f = "";
      for (var i in op) {
        var fn = this.options.prefix + "[" + n + "][" + i + "]";
        var fid = fn.replace(/]/g, "").replace(/\[/g, "_") + '"';
        f += '<input type="hidden" id="' + fid + '" name="' + fn + '" value="' + escape_field(op[i]) + '"/>';
      }
      return f;
    },

    _insert_row: function(n, v) {
      var self = this;
      var new_row = $('<tr class="oplist-del">' +
        "<th>" + escape_html(n) + "</th>" +
        '<td class="value">' + self._op_value_string(n, v) + self._op_fields(n, v) + "</td>" +
        '<td class="button"><button type="button">' + self.options.labels.edit + "</button></td>" +
        '<td class="button"><button type="button">' + self.options.labels.remove + "</button></td>" +
        "</tr>");
      var buttons = new_row.find("button");
      $(buttons[0]).button({
        icons: {
          primary: "ui-icon-pencil"
        },
        text: false
      });
      $(buttons[1]).button({
        icons: {
          primary: "ui-icon-minus"
        },
        text: false
      }).click(function(event) {
        $(this).parent().parent().fadeOut("fast", function() {
          var deleted_name = $(this).children(":first").text();
          $(this).remove();
          var new_option = "<option value='" + escape_field(deleted_name) + "'>" + escape_html(deleted_name) + "</option>";
          var options = self.new_op_select[0].options;
          var i = 0;
          for (i = 0; i < options.length; i++) {
            if (options[i].value == deleted_name) {
              // It's possible to click a fading button fast enough to insert dupes...
              return;
            }
            if (options[i].value > deleted_name) break;
          }
          if (i >= options.length) {
            // Last item
            self.new_op_select.append(new_option);
          } else {
            self.new_op_select.children("option:eq(" + i + ")").before(new_option);
          }
          self._init_new_op();
          self._trigger("dirty", event, { field: null, name: deleted_name } );
        });
      });

      self.new_op_row.before(new_row);

      self._scroll_into_view();

      return new_row;
    },

    _add_op: function(event) {
      var self = this;
      var n = self.new_op_select.val();
      if (!n) return;

      self._insert_row(n, self.options.all_ops[n]).effect("highlight", {}, 1000);

      self.new_op_select.children("option[value='" + n + "']").remove();
      self.new_op_select.val("");
      self._init_new_op();

      self._trigger("dirty", event, { field: null, name: n });
    },

    _scroll_into_view: function() {
      this.element.scrollTop(this.element.find("table tr:last").position().top);
    }

  });
})(jQuery);

