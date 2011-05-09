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
  $.widget("ui.location", {
    options: {
      rules: [],
      nodes: [],
      labels: {
        score: "Score",
        node: "Node"
      },
      prefix: "",
      dirty: null
    },

    valid: function() {
      var self = this;
      var rules = self.options.rules;
      return self._is_simple() &&
        // TODO(must): get rid of this wacky hard coded junk
        $("#location_rules__score").val() != "" &&
        $("#location_rules__expressions__value").val() != "";
    },

    _is_simple: function() {
      var self = this;
      var rules = self.options.rules;
      return rules.length == 0 ||
        rules.length == 1 && rules[0].expressions.length == 1 &&
        rules[0].score && rules[0].expressions[0].value &&
        rules[0].expressions[0].attribute == "#uname" &&
        rules[0].expressions[0].operation == "eq";
    },

    _create: function() {
      var self = this;
      var e = self.element;
      e.addClass("ui-location");
    },

    _init: function() {
      var self = this;
      if (self._is_simple()) {
        self._init_simple();
      } else {
        self.element.children().remove();
        self.element.append($("<div>NOT YET IMPLEMENTED</div>"));
      }
    },

    _init_simple: function() {
      var self = this;

      var node = "";
      var score = "";
      if (self.options.rules.length && self.options.rules[0].expressions.length) {
        score = self.options.rules[0].score;
        node = self.options.rules[0].expressions[0].value;
      }
      var e = self.element;
      e.children().remove();
      e.append($("<table>" +
          "<tr><th>" + escape_html(self.options.labels.score) + "</th><th>" + escape_html(self.options.labels.node) + "</th></tr>" +
          "<tr>" +
            '<td><input type="text" ' + self._field_name("[score]") + ' value="' + escape_field(score) + '"/></td>' +
            "<td>" + self._select(self._field_name("[expressions][][value]"), self.options.nodes, node) +
              '<input type="hidden" ' + self._field_name("[expressions][][attribute]") + ' value="#uname"/>' +
              '<input type="hidden" ' + self._field_name("[expressions][][operation]") + ' value="eq"/></td>' +
          "</tr>" +
        "</table>"));
      e.find("input[type=text]").bind("keyup change", function(event) {
        self._trigger("dirty", event, {});
      });
      e.find("select").change(function(event) {
        self._trigger("dirty", event, {});
      });
    },

    // Note: Surprisingly similar to function in ui.constraint.js
    _field_name: function(n) {
      var self = this;
      n = self.options.prefix + "[]" + n;
      return 'id="' + n.replace(/]/g, "").replace(/\[/g, "_") + '" name="' + n + '"';
    },

    _select: function(idn, opts, value) {
      var s = "<select " + idn + ">";
      if (value == "") {
        s += "<option></option>";
      } else if ($.inArray(value, opts) == -1) {
        s += "<option>" + escape_html(value) + "</option>";
      }
      $.each(opts, function(i, n) {
        s += "<option" + (n == value ? ' selected="selected"' : "") + ">" + escape_html(n) + "</option>";
      });
      s += "</select>";
      return s;
    }

  });
})(jQuery);

