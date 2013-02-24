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

// Note: this requires ui.attrlist

//
// Everything would be much easier if it weren't possible to have
// multiple monitor ops.  We need to be able to handle creating and
// editing multiple monitor ops, and also (potentially) to handle
// multiple ops in RA metadata.  So all_ops and set_ops look like
// this:
//
//    {
//      start: [
//        { timeout: "20s" }
//      ],
//      stop: [
//        { timeout: "20s" }
//      ],
//      monitor: [
//        { interval: "10s", timeout: "20s" },
//        { interval: "20s", timeout: "20s" }
//      ]
//    }
//
// i.e. it's a hash of arrays of ops.  Note that the implementation
// specifically only allows multiple monitor ops (no other op type
// can have multiple instances), and there's some hackery to ensure
// a unique interval is used for each monitor op.
//
// Note also that the hidden fields generated (almost) reflect this
// structure, the difference being the "array" part is indexed by
// the op interval, i.e.:
//
//    <input name="...[monitor][10][timeout]"/>
//    <input name="...[monitor][10][interval]"/>
//    <input name="...[monitor][20][timeout]"/>
//    <input name="...[monitor][20][interval]"/>
//    <!-- etc -->
//
// This inconsistency (array in, hash out) is intentional, it makes
// some implementation details slightly easier.
//
// TODO(should): fix the aforementioned inconsistency :)
//

// TODO(should): do we care about field for dirty event?

(function($) {
  $.widget("ui.oplist", {

    options: {
      all_ops: {},
      set_ops: {},
      labels: {
        add: "Add",
        edit: "Edit",
        remove: "Remove",
        no_value: "You must enter a value",
        duplicate_interval: "There is already a monitor op with this interval.",
        ok: "OK",
        cancel: "Cancel"
      },
      prefix: "",
      dirty: null
    },
    keypress_hack: "",

    _create: function() {
      var self = this;
      var e = self.element;
      // TODO(should): add ui-widget class (but style it properly first; fonts don't match the rest of Hawk yet)
      e.addClass("ui-oplist");
      e.append($("<table><tr>" +
        "<th><select><option></option></select></th>" +
        '<td class="value"></td>' +
        '<td class="button"><button type="button">' + escape_html(self.options.labels.edit) + "</button></td>" +
        '<td class="button"><button type="button">' + escape_html(self.options.labels.add) + "</button></td>" +
        '</tr></table><div><div style="height: 12em; overflow: auto; position: relative;"></div></div>'));
      self.new_op_row = $(e.find("tr")[0]);
      self.new_op_select = e.find("select");
      self.new_op_td = $(e.find("td")[0]);
      self.new_op_edit = $(e.find("button")[0]);
      self.new_op_edit.button({
        icons: {
          primary: "ui-icon-pencil"
        },
        text: false,
        disabled: true
      }).click(function() {
        var n = self.new_op_select.val();
        if (!n) return;
        self._edit_op(n);
      });
      self.new_op_add = $(e.find("button")[1]);
      self.new_op_add.button({
        icons: {
          primary: "ui-icon-plus"
        },
        text: false,
        disabled: true
      }).click(function(event) {
        self._add_op(event);
      });;
      self.new_op_select.keydown(function() {
        self.keypress_hack = $(this).val();
      }).bind("keyup change", function() {
        if ($(this).val() != self.keypress_hack) {
          self.keypress_hack = $(this).val();
          self._init_new_op();
        }
      });
      self.dialog = $(e.find("div")[0]);
      self.dialog.dialog({
        resizable:      false,
        width:          "34em",
        draggable:      false,
        modal:          true,
        autoOpen:       false,
        closeOnEscape:  true
      });
    },

    _init: function() {
      var self = this;

      self.element.find(".oplist-del").remove();
      self.new_op_select.children().remove();
      self.new_op_select.append($("<option></option>"));

      self._sort_ops();

      $.each(self.ops, function(i, n) {
        var inserted = false;
        if (n in self.options.set_ops) {
          $.each(self.options.set_ops[n], function(j, op) {
            self._insert_row(n, op);
          });
          inserted = true;
        }
        if (!inserted || n == "monitor") {
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
      this.new_op_edit.button("option", "disabled", n ? false : true);
      if (n) {
        this.new_op_td.text(this._op_value_string(n, this._filter_monitor_interval(n, this.options.all_ops[n][0])));
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
      var v = "";
      if ("timeout" in op) { v += "timeout: " + op.timeout + " "; }
      if (n == "monitor" && "interval" in op) {
        v += " interval: " + op.interval;
      }
      return v;
    },

    _op_fields: function(n, op) {
      var f = "";
      for (var i in op) {
        if (i == "name") continue;
        var fn = this.options.prefix + "[" + n + "][" + (op.interval ? op.interval : "0") + "][" + i + "]";
        var fid = fn.replace(/]/g, "").replace(/\[/g, "_");
        f += '<input type="hidden" id="' + fid + '" name="' + fn + '" value="' + escape_field(op[i]) + '"/>';
      }
      return f;
    },

    // Returns an array of rows which contain monitor ops that already have the given interval.
    _monitor_rows_with_interval: function(i) {
      var id = this.options.prefix.replace(/]/g, "").replace(/\[/g, "_") + "_monitor_" + i + "_interval";
      return this.element.find("input#" + id).parent().parent();
    },

    // TODO(must): _edit_op was largely duplicated from this - consolidate!
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
      }).click(function() {
        var this_row = $(this).parent().parent();
        var op_name = this_row.children(":first").text();
        var set_attrs = {};
        this_row.find("input").each(function() {
          var n = this.name.match(/.*\[([^\]]+)\]$/)[1];
          if (op_name != "monitor" && n == "interval" && this.value == "0") {
            // Exclude interval=0 from the list of set attributes
            // if we're not editing a monitor op (it'll ultimately
            // be set anyway, but the UI is cleaner without this)
          } else {
            set_attrs[n] = this.value;
          }
        });
        self.dialog.children(":first").attrlist({
          labels: {
            add: self.options.labels.add,
            remove: self.options.labels.remove,
            no_value: self.options.labels.no_value
          },
          all_attrs: {
            "interval": {
              "type":     "string",
              "default":  self.options.all_ops[op_name][0]["interval"] || 0,
              "required": op_name == "monitor"
            },
            "timeout": {
              "type":     "string",
              "default":  self.options.all_ops[op_name][0]["timeout"],
              "required": true
            },
            // Default for "requires" is actually "nothing" for STONITH
            // resources, and for everything else "fencing" if STONITH
            // is enabled, otherwise "quorum".
            "requires": {
              "type":     "enum",
              "default":  "fencing",
              "values":   ["nothing", "quorum", "fencing"]
            },
            "enabled": {
              "type":     "boolean",
              "default":  "true"
            },
            // TODO(should): remove "role"?  Somewhat advanced, methinks...
            "role": {
              "type":     "enum",
              "default":  "",
              "values":   ["Stopped", "Started", "Slave", "Master"]
            },
            // Default for "on-fail" for "stop" ops is "fence" when
            // STONITH is enabled and "block" otherwise.  All other ops
            // default to "stop".
            "on-fail": {
              "type":     "enum",
              "default":  "stop",
              "values":   ["ignore", "block", "stop", "restart", "standby", "fence"]
            },
            "start-delay": {
              "type":     "string",
              "default":  "0"
            },
            "interval-origin": {
              "type":     "string",
              "default":  "0"
            },
            "record-pending": {
              "type":     "boolean",
              "default":  "false"
            },
            "description": {
              "type":     "string",
              "default":  ""
            }
          },
          set_attrs: set_attrs,
          prefix: "op_attrs",
          dirty: function() {
            // Make sure everything has values
            var enabled = true;
            $.each(self.dialog.children(":first").attrlist("val"), function(n,v) {
              if (v === "") {
                enabled = false;
                return false;
              }
            });
            if (enabled) {
              self.dialog.parent().find(".ui-dialog-buttonpane button:first").removeAttr("disabled");
            } else {
              self.dialog.parent().find(".ui-dialog-buttonpane button:first").attr("disabled", "disabled");
            }
          }
        });
        var b = {};
        // TODO(must): trim interval!
        b[self.options.labels.ok] = function(event) {
          var v = self.dialog.children(":first").attrlist("val");
          if (op_name == "monitor") {
            // ensure there's no duplicate intervals for monitor ops
            var duplicate = false;
            self._monitor_rows_with_interval(v.interval).each(function() {
              if (this != this_row[0]) {
                duplicate = true;
                return false;
              }
            });
            if (duplicate) {
              // TODO(should): Integrate this error display into the dialog
              // rather than having an (ugly) alert box.
              alert(self.options.labels.duplicate_interval);
              return;
            }
          }
          $(this_row.children("td")[0]).html(self._op_value_string(op_name, v) + self._op_fields(op_name, v));
          $(this).dialog("close");
          self._trigger("dirty", event, { field: null, name: op_name } );
        };
        b[self.options.labels.cancel] = function() {
          $(this).dialog("close");
        };
        self.dialog.dialog("option", {
          title:    op_name,
          buttons:  b,
          open:     function() {
            $(this).parent().find(".ui-dialog-buttonpane button:first").attr("disabled", "disabled");
          },
          close:    function() {
            // Get rid of attrlist when dialog closes, else it pollutes
            // the parent form with hidden fields).
            self.dialog.children(":first").attrlist({ all_attrs: {}});
          }
        }).dialog("open");
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
          if (deleted_name != "monitor") {
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
          }
          self._init_new_op();
          self._trigger("dirty", event, { field: null, name: deleted_name } );
        });
      });

      self.new_op_row.before(new_row);

      self._scroll_into_view();

      return new_row;
    },

    _next_monitor_interval: function(interval) {
      while (this._monitor_rows_with_interval(interval).length != 0) {
        // Conversion to/from String here is probably over-paranoid
        var m = new String(interval).match(/([0-9]+)(.*)/);
        interval = new String(parseInt(m[1]) + 1);
        if (m.length == 3) {
          interval += m[2];
        }
      }
      return interval;
    },

    // Returns a new monitor op, with a unique interval (or just a copy
    // of the op passed in if this is not a monitor op).
    // TODO(should): it's a bit freakish having this called from both
    // _add_op() and _init_new_op()
    _filter_monitor_interval: function(n, op) {
      if (n != "monitor") return op;
      var mop = $.extend(true, {}, op);
      mop.interval = this._next_monitor_interval(mop.interval);
      return mop;
    },

    _add_op: function(event) {
      var self = this;
      var n = self.new_op_select.val();
      if (!n) return;

      self._insert_row(n, self._filter_monitor_interval(n, self.options.all_ops[n][0])).effect("highlight", {}, 1000);
      if (n != "monitor") {
        self.new_op_select.children("option[value='" + n + "']").remove();
      }

      self.keypress_hack = "";
      self.new_op_select.val("");
      self._init_new_op();

      self._trigger("dirty", event, { field: null, name: n });
    },

    // TODO(must): this is largely duplicated from _insert_row, but with some
    // subtle differences - consolidate!
    _edit_op: function(op_name) {
      var self = this;
      var set_attrs = {};
      var interval = self.options.all_ops[op_name][0]["interval"];
      if (op_name == "monitor") {
        interval = self._next_monitor_interval(interval);
      }
      self.dialog.children(":first").attrlist({
        labels: {
          add: self.options.labels.add,
          remove: self.options.labels.remove,
          no_value: self.options.labels.no_value
        },
        all_attrs: {
          "interval": {
            "type":     "string",
            "default":  interval || 0,
            "required": op_name == "monitor"
          },
          "timeout": {
            "type":     "string",
            "default":  self.options.all_ops[op_name][0]["timeout"],
            "required": true
          },
          // Default for "requires" is actually "nothing" for STONITH
          // resources, and for everything else "fencing" if STONITH
          // is enabled, otherwise "quorum".
          "requires": {
            "type":     "enum",
            "default":  "fencing",
            "values":   ["nothing", "quorum", "fencing"]
          },
          "enabled": {
            "type":     "boolean",
            "default":  "true"
          },
          // TODO(should): remove "role"?  Somewhat advanced, methinks...
          "role": {
            "type":     "enum",
            "default":  "",
            "values":   ["Stopped", "Started", "Slave", "Master"]
          },
          // Default for "on-fail" for "stop" ops is "fence" when
          // STONITH is enabled and "block" otherwise.  All other ops
          // default to "stop".
          "on-fail": {
            "type":     "enum",
            "default":  "stop",
            "values":   ["ignore", "block", "stop", "restart", "standby", "fence"]
          },
          "start-delay": {
            "type":     "string",
            "default":  "0"
          },
          "interval-origin": {
            "type":     "string",
            "default":  "0"
          },
          "record-pending": {
            "type":     "boolean",
            "default":  "false"
          },
          "description": {
            "type":     "string",
            "default":  ""
          }
        },
        set_attrs: set_attrs,
        prefix: "op_attrs",
        dirty: function() {
          // Make sure everything has values
          var enabled = true;
          $.each(self.dialog.children(":first").attrlist("val"), function(n,v) {
            if (v === "") {
              enabled = false;
              return false;
            }
          });
          if (enabled) {
            self.dialog.parent().find(".ui-dialog-buttonpane button:first").removeAttr("disabled");
          } else {
            self.dialog.parent().find(".ui-dialog-buttonpane button:first").attr("disabled", "disabled");
          }
        }
      });
      var b = {};
      // TODO(must): trim interval!
      b[self.options.labels.ok] = function(event) {
        var v = self.dialog.children(":first").attrlist("val");
        if (op_name == "monitor") {
          // ensure there's no duplicate intervals for monitor ops
          var duplicate = false;
          self._monitor_rows_with_interval(v.interval).each(function() {
            duplicate = true;
            return false;
          });
          if (duplicate) {
            // TODO(should): Integrate this error display into the dialog
            // rather than having an (ugly) alert box.
            alert(self.options.labels.duplicate_interval);
            return;
          }
        }

        // begin ~dupe of _add_op
        self._insert_row(op_name, v).effect("highlight", {}, 1000);
        if (op_name != "monitor") {
          self.new_op_select.children("option[value='" + n + "']").remove();
        }
        self.keypress_hack = "";
        self.new_op_select.val("");
        self._init_new_op();
        self._trigger("dirty", event, { field: null, name: op_name });
        // end ~dupe of _add op

        $(this).dialog("close");
      };
      b[self.options.labels.cancel] = function() {
        $(this).dialog("close");
      };
      self.dialog.dialog("option", {
        title:    op_name,
        buttons:  b,
        open:     function() {
          $(this).parent().find(".ui-dialog-buttonpane button:first").removeAttr("disabled");
        },
        close:    function() {
          // Get rid of attrlist when dialog closes, else it pollutes
          // the parent form with hidden fields).
          self.dialog.children(":first").attrlist({ all_attrs: {}});
        }
      }).dialog("open");
    },

    _scroll_into_view: function() {
      this.element.scrollTop(this.element.find("table tr:last").position().top);
    },

    empty: function() {
      return this.element.find(".oplist-del").length == 0;
    }

  });
})(jQuery);

