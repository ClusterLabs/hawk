// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

// ops and values is:
//
// {
//  start: { timeout: 20 }
//  stop: { timeout: 20 }
//  monitor_10 : { interval: 10s, timeout: 20s }
//  monitor_20 : { interval: 20s, timeout: 20s }
// }
//
// That is, monitor operations have a generated name that
// combines the name and the interval. This is so that there
// can be multiple monitor operations.

;(function($) {
  'use strict';

  $.views.converters("complexOp", function(op) {
    console.log(op);
    if ($.grep(Object.keys(op), function(k) {
      return k.match(/interval|timeout|name|role|jQuery\d+/) === null;
    }).length > 0) {
      return '<i class="fa fa-ellipsis-h fa-fw text-muted"></i>&nbsp;';
    } else {
      return "";
    }
  });

  function OpList(el, options) {
    this.$el = $(el);

    // defined actions: [{name, interval, ...}]
    this.values = this.$el.data('oplist');
    this.targets = this.$el.data('oplist-target');
    this.prefixes = this.$el.data('oplist-prefix');

    var actions = {};
    var monitor_arr = [];
    $.each(this.$el.data('oplist-actions'), function(i, action) {
      if (!(action.name in actions) || action.name == "monitor") {
        var obj = {};
        $.each(action, function(k, v) {
          if (k != "name" && k != "depth") {
            obj[k] = v;
          }
        });

        if (action.name == "monitor") {
          if (!("interval" in obj) || !obj.interval) {
            obj.interval = "20s";
          }
          monitor_arr.push(obj);
        } else {
          actions[action.name] = obj;
        }
      }
    });
    actions["monitor"] = monitor_arr;
    this.actions = actions;

    this.available = Object.keys(actions);

    // mapping in the oplist is the mapping used to set
    // operation attributes in the operation edit modal
    // no need for available etc, that stuff is handled
    // by the modal attrlist
    this.attr_mapping = this.$el.data('oplist-mapping');

    this.defaults = {
      create: false, // if true, creating a new resource: add operations for actions
      labels: {
        create: __('Create'),
        edit: __('Edit'),
        remove: __('Remove'),
        trueish: __('Yes'),
        falseish: __('No'),
        add: __('Add'),
        apply: __('Apply')
      },

      entryTemplate: [
        '<div class="form-group {{>op.name}}" data-element="{{>id}}" data-help-filter=".row.op-{{>op.name}}">',
          '{{props op}}',
            '<input type="hidden" name="{{>~root.prefix}}[{{>~root.id}}][{{>key}}]" value="{{>prop}}">',
          '{{/props}}',
          '<div class="col-lg-5">',
          '</div>',
          '<div class="col-sm-12 col-lg-7">',
            '<div class="list-group-item">',
              '<code>',
                '{{>op.name}}',
              '</code>',
              '<div class="pull-right">',
                '{{if op.timeout}}',
                  '<span class="label label-default" title="timeout" data-toggle="tooltip">{{>op.timeout}}</span>&nbsp;',
                '{{/if}}',
                '{{if op.interval}}',
                  '<span class="label label-info" title="interval" data-toggle="tooltip">{{>op.interval}}</span>&nbsp;',
                '{{/if}}',
                '{{if op.role}}',
                  '<span class="label label-info" title="role" data-toggle="tooltip">{{>op.role[0]}}</span>&nbsp;',
                '{{/if}}',
                '{{complexOp:op}}',
                '<a class="edit btn btn-xs btn-default" title="{{>labels.edit}}" data-attr="{{>id}}" data-name="{{>op.name}}"><i class="fa fa-pencil fa-fw"></i></a>',
                '<a class="remove btn btn-xs btn-default" title="{{>labels.remove}}" data-attr="{{>id}}" data-name="{{>op.name}}"><i class="fa fa-minus fa-fw"></i></a>',
              '</div>',
            '</div>',
          '</div>',
        '</div>'
      ].join(''),

      adderTemplate: [
        '<div class="form-group addition">',
          '<div class="col-sm-5">',
          '</div>',

          '<div class="col-sm-7 setter">',
            '<div class="input-group">',
              '<select class="form-control select ignore" name="temp[selector]">',
                '<option></option>',
                '{{for available}}',
                  '<option value="{{>#data}}">',
                    '{{>#data}}',
                  '</option>',
                '{{/for}}',
              '</select>',
              '<div class="input-group-btn">',
                '<a href="#" class="create btn btn-default" title="{{>labels.create}}">',
                  '<i class="fa fa-plus fa-lg fa-fw"></i>',
                '</a>',
              '</div>',
            '</div>',
          '</div>',
        '</div>'
      ].join(''),

      editTemplate: [
        '<form role="form" class="form-horizontal">',
          '<input type="hidden" name="op[id]" value="{{>id}}">',
          '<input type="hidden" name="op[name]" value="{{>name}}">',
          '<div class="modal-header">',
            '<h3 class="modal-title">',
              '{{>name}}',
            '</h3>',
          '</div>',
          '<div class="modal-body" data-help-target="#oplist-edit-help > .row">',
            '<fieldset data-attrlist="" data-attrlist-target=".content" data-attrlist-prefix="op">',
              '<div class="content">',
            '</fieldset>',
            '<div id="oplist-edit-help" class="container-fluid">',
              '{{props mapping}}',
              '<div class="row help-block {{>key}}" style="display: none;">{{>prop.longdesc}}</div>',
              '{{/props}}',
            '</div>',
          '</div>',
          '<div class="modal-footer">',
            '<input type="submit" name="submit" value="{{>submit}}" class="btn btn-primary submit">',
          '</div>',
        '</form>'
      ].join('')
    };

    this.options = $.extend(
      this.defaults,
      options
    );

    $.templates({
      entryTemplate: this.options.entryTemplate,
      adderTemplate: this.options.adderTemplate,
      editTemplate: this.options.editTemplate
    });

    this.init();
  }

  OpList.prototype.init = function() {
    var self = this;

    var content = {
      labels: self.options.labels,
      prefix: self.prefixes,
      actions: self.actions,
      values: self.values,
      available: self.available,
    };

    var uniquify_interval = function(interval) {
      var m = /([0-9]+)\s*(s|m|h)?/.exec(interval);
      if (!m || !m[2]) {
        return interval;
      } else if (m[2] == "s") {
        return m[1];
      } else if (m[2] == "m") {
        return (parseInt(m[1]) * 60).toString();
      } else if (m[2] == "h") {
        return (parseInt(m[1]) * 60 * 60).toString();
      }
    };

    // add default operations
    if (self.options.create) {
      $.each(self.actions, function(name, info) {
        if (name == "start" || name == "stop") {
          var op = { name: name };
          $.each(info, function(key, val) {
            op[key] = val;
          });
          var id = name;
          content.available.splice($.inArray(name, content.available), 1);
          content.values[id] = op;
        }
        if (name == "monitor") {
          $.each(info, function(i, item){
            if (info.length > 2 && "role" in item) {
                return;
            } else {
              var op = {name: name};
              $.each(item, function(key, val) {
                op[key] = val;
              });
              var id = name;
              id += "_" + uniquify_interval(op.interval);
              content.values[id] = op;
            }
          });
        }
      });
    }

    var tgtnode = self.$el.find(self.targets);
    tgtnode.html([
      '<div class="oplist-items"/>',
      '<div class="oplist-adder"/>'
    ].join(""));
    var itemhook = tgtnode.find('.oplist-items');
    var addhook = tgtnode.find('.oplist-adder');
    addhook.html($.templates.adderTemplate.render(content));

    $.each(content.values, function(id, op) {
      var data = {
        labels: content.labels,
        prefix: content.prefix,
        actions: content.actions,
        values: content.values,
        id: id,
        op: op
      };
      itemhook.append($.templates.entryTemplate.render(data));
    });
    itemhook.find('[data-toggle]').tooltip();

    var MODAL_MODE_CREATE = 0;
    var MODAL_MODE_EDIT = 1;
    var show_operation_modal = function(edit_mode, id, name) {
      var submit_text = (edit_mode == MODAL_MODE_CREATE) ? content.labels.add : content.labels.apply;
      if (!name)
        name = id;
      var attrmapping = self.attr_mapping;
      var modal = $('#modal');
      var medit = $.templates.editTemplate.render({id: id, name: name, submit: submit_text, mapping: attrmapping});
      modal.find('.modal-content').html(medit);
      var alist = modal.find('[data-attrlist]');
      if (id in content.values) {
        alist.data('attrlist', content.values[id]);
      } else {
        alist.data('attrlist', content.actions[name]);
      }

      // special case for OCF_CHECK_LEVEL
      if (name == "monitor") {
        attrmapping = $.extend({OCF_CHECK_LEVEL: {type: "string", default: "0"} },
                               self.attr_mapping);
      }

      $.each(attrmapping, function(k) {
        if (k.match(/jQuery\d+/)) {
          delete attrmapping[k];
        }
      });
      alist.data('attrlist-mapping', attrmapping);
      alist.attrList();
      modal.modal('show');
      modal.find('form').submit(function(event) {
        event.preventDefault();

        // TODO: calculate monitor id, check if op already exists
        var values = $(this).serializeArray();
        var opid = null;
        var op = {};
        $.each(values, function(i, item) {
          var rename = /op\[(.+)\]/.exec(item.name);
          if (rename != null) {
            if (rename[1] != "id") {
              op[rename[1]] = item.value;
            } else {
              opid = item.value;
            }
          }
        });

        if (op.name == "monitor") {
          if (!("interval" in op)) {
            modal.modal('hide');
            $.growl({
              message: __("No interval set for monitor operation")
            },{
              type: 'danger'
            });
            return;
          }
          opid = op.name + "_" + uniquify_interval(op.interval);
        }

        var replacing = false;
        if (opid in content.values || edit_mode == MODAL_MODE_EDIT) {
          replacing = true;
        }

        var data = {
          labels: content.labels,
          prefix: content.prefix,
          actions: content.actions,
          values: content.values,
          id: opid,
          op: op
        };
        var rendered = $.templates.entryTemplate.render(data);
        if (replacing) {
          itemhook.find('[data-element="' + id + '"]').replaceWith(rendered);
          if (edit_mode == MODAL_MODE_EDIT && (opid != id) && (id in content.values))
            delete content.values[id];
        } else {
          itemhook.append(rendered);
        }
        itemhook.find('[data-toggle]').tooltip();
        content.values[opid] = op;

        // 2. re-render the select
        if (op.name != "monitor") {
          var toremove = 'option[value="' + opid + '"]';
          tgtnode.find('.setter select').find('option:selected').remove();
          content.available.splice($.inArray(opid, content.available), 1);
        } else {
          tgtnode.find('.setter select').val('');
        }

        modal.modal('hide');

        if (replacing && edit_mode != MODAL_MODE_EDIT) {
          $.growl({
            message: __("Replacing previously defined monitor operation with same interval")
          },{
            type: 'warning'
          });
        }
      });
    };

    tgtnode.on('keyup change', 'input, select', function(e) {
      // Trigger the plus sign programmatically
      $('.addition .setter .create').click();
      $(e.delegateTarget)
        .parents('form')
        .find('[name="revert"]')
        .show()
        .end()
        .find('a.back')
        .attr('data-confirm', __('Any changes will be lost - do you wish to proceed?'))
        .end();
    }).on('click', '.addition .setter .create', function(e) {
      e.preventDefault();
      var id = tgtnode.find('.setter select').val();
      if (id.length == 0 || (id != "monitor" && id in content.values))
        return;
      show_operation_modal(MODAL_MODE_CREATE, id);
    }).on('click', '.remove', function(e) {
      e.preventDefault();
      var id = $(this).data('attr');
      var name = $(this).data('name');

      // 0. remove from values
      delete content.values[id];

      // 1. remove from entries
      itemhook.find('[data-element="' + id + '"]').remove();

      // 2. add to available
      if (name != "monitor") {
        content.available.push(name);
        content.available.sort();

        // 3. re-render the select
        var adder = tgtnode.find('.setter select');
        adder.append('<option value="' + name + '">' + name + '</option>');
        var new_options = adder.find('option');
        new_options.sort(function(a, b) { return a.text.localeCompare(b.text); });
        adder.empty().append(new_options).val('');
      }

    }).on('click', '.edit', function(e) {
      var id = $(this).data('attr');
      var name = $(this).data('name');
      show_operation_modal(MODAL_MODE_EDIT, id, name);
    }).on('change', '.setter select', function(e) {
      var val = $(this).val();
      if (val && content.actions[val]) {
        var filter = "." + val;
        tgtnode.find('.setter').attr("data-help-filter", filter);
        $('[data-help-target]').each(function() {
          $($(this).data('help-target')).hide().filter(filter).show();
        });
      } else {
        tgtnode.find('.setter').removeAttr("data-help-filter");
      }
    });
  };

  $.fn.opList = function(options) {
    return this.each(function() {
      new OpList(this, options);
    });
  };
}(jQuery));

$(function() {
  $('[data-oplist]').opList();
});
