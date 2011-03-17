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

// ui.attrlist is an editable table of "attributes" (options,
// parameters, properties, whatever).  Minimally, you need to supply
// all_attrs and a prefix for form field names (this will become
// "prefix[name]" for each attribute in the form).  For example:
//
// $("#mydiv").attrlist({
//   all_attrs: {
//     "is-managed-default": {
//       "type":       "boolean",
//       "longdesc":   "should the cluster...",
//       "shortdesc":  "start/stop resources as required",
//       "readonly":   false,
//       "advanced":   false,
//       "default":    true,   // or a string, depends on type
//       "required":   false
//     },
//     "batch-limit": {
//       "type":       "integer",
//       // ...
//     }
//   },
//   prefix: "props"
// });
//
// Every attribute must have a "type" and a "default" value.
// Everything else is (or should be) optional.
//
// Required attributes will be listed first, and are not able to
// be removed from the table.
//
// You can also pass in "set_attrs", which is a map of any currently
// set attributes and their values, "labels" which are for
// localized text display, and "dirty" which is a callback invoked
// when an attribute is added or removed, or a value is changed.
// The dirty callback is passed the browser event and a hash
// containing "field" and "name", being the field that changed and
// the name of the corresponding attribute.  field will be null
// when a row is deleted.
//

// TODO(should): ESC key on field to hide no_value error
// TODO(should): cope with yes/no booleans
// TODO(should): something better (position-wise) with "you must enter a value"?
// TODO(should): focus value field on select (maybe)
// TODO(should): alphabetize when user adds new row, instead of insert at bottom?

(function($) {
  $.widget("ui.attrlist", {

    options: {
      all_attrs: {},
      set_attrs: {},
      labels: {
        add: "Add",
        remove: "Remove",
        no_value: "You must enter a value",
        heading_add: null,
        heading_edit: null
      },
      prefix: "",
      dirty: null
    },
    required_attrs: [],
    optional_attrs: [],
    keypress_hack: "",

    _create: function() {
      // Can't use real 'this' inside $.each(), or in event handlers,
      // so use 'self' throughout for "consistency".
      var self = this;
      var e = self.element;
      // TODO(should): add ui-widget class (but style it properly first; fonts don't match the rest of Hawk yet)
      e.addClass("ui-attrlist");
      e.append($("<table><tr>" +
          (self.options.labels.heading_add ? '<th class="label" colspan="3" style="padding-top: 1em;">' + escape_html(self.options.labels.heading_add) + "</th></tr><tr>" : '') +
          "<th><select><option></option></select></th>" +     // must have empty option, or IE can't manipulate this (*gah*)
          '<td class="value"></td>' +
          '<td><button type="button">' + escape_html(self.options.labels.add) + "</button></td>" +
        "</tr><tr>" +
          "<td></td>" +
          '<td class="value"><div class="ui-state-error ui-corner-all" style="display: none;">' +
            escape_html(self.options.labels.no_value) + "</div></td>" +
        "</tr></table>"));
      self.new_attr_row = $(e.find("tr")[0]);
      self.no_value = e.find("div");
      self.new_attr_select = e.find("select");
      self.new_attr_td = $(e.find("td")[0]);
      self.new_attr_add = e.find("button");
      self.new_attr_add.button({
        icons: {
          primary: "ui-icon-plus"
        },
        text: false,
        disabled: true
      }).click(function(event) {
        self._add_attr(event);
      });;
      self.new_attr_select.keydown(function() {
        self.keypress_hack = $(this).val();
      }).bind("keyup change", function() {
        // Need both keyup and change.  Unfortunately we have
        // to track the value manually (keypress_hack), else
        // this would trigger when hitting ESC or TAB, which
        // would re-initialize the field, even though nothing
        // has changed.  We use the same event for "change",
        // to again avoid double triggering on losing field
        // focus after a keypress.
        // TODO(should): Find a cleaner way to do this.
        if ($(this).val() != self.keypress_hack) {
          self.keypress_hack = $(this).val();
          self.no_value.fadeOut("fast");
          self._init_new_value_field();
          self._show_help($(this).val());
        }
      });
    },

    _init: function() {
      var self = this;

      self.element.find(".attrlist-del").remove();
      self.new_attr_select.children().remove();
      self.new_attr_select.append($("<option></option>"))
      self.new_attr_td.children().remove();
      self.no_value.hide();

      self._sort_attrs();

      $.each(self.required_attrs, function(i, n) {
        // Insert required attributes with disabled 'remove' button
        self._insert_row(n,
          n in self.options.set_attrs ? self.options.set_attrs[n] : self.options.all_attrs[n]["default"],
          true);
      });
      $.each(self.optional_attrs, function(i, n) {
        if (self.options.all_attrs[n].advanced ||
            self.options.all_attrs[n].readonly) {
          return;
        }
        if (n in self.options.set_attrs) {
          // Insert any existing, set, but optional attributes
          self._insert_row(n,
            n in self.options.set_attrs ? self.options.set_attrs[n] : self.options.all_attrs[n]["default"]);
        } else {
          // Otherwise just add the attribute name to the new attribute select
          self.new_attr_select.append($('<option value="' + escape_html(n) + '">' + escape_html(n) + "</option>"));
        }
      });

      self._init_new_value_field();
    },

    _sort_attrs: function() {
      this.required_attrs = [];
      this.optional_attrs = [];
      for (var n in this.options.all_attrs) {
        if (this.options.all_attrs[n].required) {
          this.required_attrs.push(n);
        } else {
          this.optional_attrs.push(n);
        }
      }
      this.required_attrs.sort();
      this.optional_attrs.sort();
    },

    // Initialize appropriate field for editing a particular value
    _init_value_field: function(td, n, v) {
      td.children().remove();
      if (!n) {
        td.append('<input type="text" value="" disabled="disabled" />');
        return;
      }
      if (v == null) v = "";
      var fn = this.options.prefix + "[" + n + "]"
      var fid = ' id="' + fn.replace(/]/g, "").replace(/\[/g, "_") + '"'
      fn = ' name="' + fn + '"'
      switch (this.options.all_attrs[n].type) {
        case "boolean":
          td.append(
            "<input" + fid + fn + ' type="hidden" value="false"/>' +
            "<input" + fid + fn + ' type="checkbox" value="true"' +
              (v == "true" || v == true ? ' checked="checked"' : '') + '"/>');
              // Note: test above for real boolean may not be necessary...
          break;
        case "enum":
          var select="<select" + fid + fn + ' class="attr-edit">';
          for (var i = 0; i < this.options.all_attrs[n]["values"].length; i++) {
            select += '<option value="' + escape_field(this.options.all_attrs[n]["values"][i]) + '"' +
              (this.options.all_attrs[n]["values"][i] == v ? ' selected="selected"' : "") +
              '>' + escape_html(this.options.all_attrs[n]["values"][i]) + "</option>";
          }
          select += "</select>";
          td.append(select);
          break;
        default:
          td.append(
            "<input" + fid + fn + ' type="text" value="' + escape_field(v) + '"/>');
          break;
      }
      var self = this;
      td.children(":last").keypress(function(e) {
        // Don't allow ENTER in value fields (would submit the form)
        return e.keyCode != 13;
      }).focus(function() {
        // Is there a better way to do this?
        self._show_help($(this).parent().prev().text());
      }).bind("keyup change", function(event) {
        self._trigger("dirty", event, { field: $(this), name: n });
      });

    },

    // Initialize the value field for adding a new attr/value row
    _init_new_value_field: function() {
      var n = this.new_attr_select.val();
      var v = n ? this.options.all_attrs[n]["default"] : null;
      this._init_value_field(this.new_attr_td, n, v);
      this.new_attr_add.button("option", "disabled", n ? false : true);
      if (this.new_attr_select[0].options.length == 1) {
        this.new_attr_select.attr("disabled", "disabled");
      } else {
        this.new_attr_select.removeAttr("disabled");
      }

      var self = this;
      // Don't want generic field event handlers here
      this.new_attr_td.children(":last").unbind().keypress(function(event) {
        // Use ENTER to add the new attribute row
        if (event.keyCode != 13) return true;
        self._add_attr(event);
        return false;
      }).focus(function() {
        self._show_help(self.new_attr_select.val());
      });
    },

    _insert_row: function(n, v, disabled) {
      disabled = disabled || false;
      var self = this;
      var new_row = $(
        ($(".attrlist-del").length == 0 && self.options.labels.heading_edit ? '<tr class="attrlist-del"><th class="label" colspan="3" style="padding-top: 1em;">' + escape_html(self.options.labels.heading_edit) + "</th></tr>" : '') +
          '<tr class="attrlist-del">' +
          "<th>" + escape_html(n) + "</th>" +
          '<td class="value"></td>' +
          '<td><button type="button">' + self.options.labels.remove + "</button></td>" +
        "</tr>");
      new_row.find("button").button({
        icons: {
          primary: "ui-icon-minus"
        },
        text: false,
        disabled: disabled
      }).click(function(event) {
        $(this).parent().parent().fadeOut("fast", function() {
          var deleted_name = $(this).children(":first").text();
          $(this).remove();
          // Inject the property back into the new properties list
          var new_option = "<option value='" + escape_field(deleted_name) + "'>" + escape_html(deleted_name) + "</option>";
          var options = self.new_attr_select[0].options;
          var i = 0;
          for (i = 0; i < options.length; i++)
          {
            if (options[i].value == deleted_name) {
              // It's possible to click a fading button fast enough to insert dupes...
              return;
            }
            if (options[i].value > deleted_name) break;
          }
          if (i >= options.length) {
            // Last item
            self.new_attr_select.append(new_option);
          } else {
            self.new_attr_select.children("option:eq(" + i + ")").before(new_option);
          }
          self._init_new_value_field();
          if (self.options.labels.heading_edit && $(".attrlist-del").length == 1) {
            $(".attrlist-del").remove();
          }
          self._trigger("dirty", event, { field: null, name: deleted_name } );
        });
      });;
      self._init_value_field($(new_row.children("td")[0]), n, v);

      self.new_attr_row.before(new_row);

      self._scroll_into_view();

      return new_row;
    },

    _add_attr: function(event) {
      var self = this;
      var n = self.new_attr_select.val();
      if (!n) return;
      var f = self.new_attr_td.children(":last");
      var v = f.val();
      if (!v) {
        self.no_value.fadeIn("fast");
        self._scroll_into_view();
        f.focus();
        return;
      }
      self.no_value.fadeOut("fast");

      self._insert_row(n, f[0].type == "checkbox" ? f[0].checked : v).effect("highlight", {}, 1000);

      // remove from new dropdown, select first, blank out
      self.new_attr_select.children("option[value='" + n + "']").remove();
      self.new_attr_select.val("");
      self._init_new_value_field();

      self._trigger("dirty", event, { field: f, name: n });
    },

    _show_help: function(n) {
      var h = $("#help");
      if (!h.length) return;
      if (this.options.all_attrs[n] && (this.options.all_attrs[n].shortdesc || this.options.all_attrs[n].longdesc)) {
        $("#help-name").html(escape_html(n));
        $("#help-shortdesc").html(escape_html(this.options.all_attrs[n].shortdesc));
        $("#help-longdesc").html(this.options.all_attrs[n].longdesc != this.options.all_attrs[n].shortdesc
          ? escape_html(this.options.all_attrs[n].longdesc) : "");
        $("#help").show();
      } else {
        $("#help").hide();
      }
    },

    _scroll_into_view: function() {
      this.element.scrollTop(this.element.find("table tr:last").position().top);
    }
  });
})(jQuery);

