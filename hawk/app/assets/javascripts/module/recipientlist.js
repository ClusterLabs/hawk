// Copyright (c) 2016 Kristoffer Gronlund <kgronlund@suse.com>
// See COPYING for license.

;(function($) {
  'use strict';

  function RecipientList(el, options) {
    this.$el = $(el);

    // defined actions: [{name, interval, ...}]
    this.values = this.$el.data('recipients');
    this.targets = this.$el.data('recipients-target');
    this.prefixes = this.$el.data('recipients-prefix');
    this.create_count = 1;

    this.defaults = {
      create: false, // if true, creating a new resource: add operations for actions
      labels: {
        create: __('Add Recipient'),
        edit: __('Edit Recipient'),
        remove: __('Remove Recipient'),
        trueish: __('Yes'),
        falseish: __('No'),
        add: __('Add'),
        apply: __('Apply'),
        recipient: __('To'),
        params: __('Instance Attributes'),
        meta: __('Meta Attributes'),
      },

      entryTemplate: [
        '<div class="form-group" data-element="{{>recipient.id}}">',
          '<input type="hidden" name="{{>~root.prefix}}[{{>~root.recipient.id}}][id]" value="{{>recipient.id}}">',
          '<input type="hidden" name="{{>~root.prefix}}[{{>~root.recipient.id}}][value]" value="{{>recipient.value}}">',
          '{{props recipient.params}}',
            '<input type="hidden" name="{{>~root.prefix}}[{{>~root.recipient.id}}][params][{{>key}}]" value="{{>prop}}">',
          '{{/props}}',
          '{{props recipient.meta}}',
            '<input type="hidden" name="{{>~root.prefix}}[{{>~root.recipient.id}}][meta][{{>key}}]" value="{{>prop}}">',
          '{{/props}}',
          '<label class="col-sm-5 control-label" for="value">{{>labels.recipient}}</label>',
          '<div class="col-sm-7">',
            '<div class="input-group">',
             '<input type="text" class="form-control" value="{{>recipient.value}}" readonly>',
              '<span class="input-group-btn">',
                '<a class="edit btn btn-default" title="{{>labels.edit}}" data-entry="{{>recipient.id}}" data-value="{{>recipient.value}}"><i class="fa fa-pencil fa-fw"></i></a>',
              '</span>',
              '<span class="input-group-btn">',
                '<a class="remove btn btn-default" title="{{>labels.remove}}" data-entry="{{>recipient.id}}" data-value="{{>recipient.value}}"><i class="fa fa-minus fa-fw"></i></a>',
              '</span>',
            '</div>',
          '</div>',
        '</div>'
      ].join(''),

      adderTemplate: [
        '<div class="form-group addition">',
          '<div class="col-sm-5">',
          '</div>',

          '<div class="col-sm-7 setter">',
            '<a href="#" class="create btn btn-default" title="{{>labels.create}}">',
              '<i class="fa fa-plus fa-lg fa-fw"></i>',
            '</a>',
          '</div>',
        '</div>'
      ].join(''),

      editTemplate: [
        '<form role="form" class="form-horizontal">',
          '<input type="hidden" name="id" value="{{>id}}">',
          '<div class="modal-header">',
            '<h3 class="modal-title">{{>title}}</h3>',
          '</div>',
          '<div class="modal-body">',
            '<div class="form-group">',
              '<label class="col-sm-5 control-label" for="path">Path</label>',
              '<div class="col-sm-7">',
                '<input class="form-control text-field" type="text" value="{{>value}}" name="value" id="path">',
              '</div>',
            '</div>',
            '<fieldset id="recipient-params-list" data-attrlist="" data-attrlist-target=".content" data-attrlist-prefix="recipient[params]" data-attrlist-freeform="yes">',
              '<legend>{{>labels.params}}<span class="pull-right toggleable"><i class="fa fa-chevron-up"></i></span></legend>',
              '<div class="content"></div>',
            '</fieldset>',
            '<fieldset id="recipient-meta-list" data-attrlist="" data-attrlist-target=".content" data-attrlist-prefix="recipient[meta]">',
              '<legend>{{>labels.meta}}<span class="pull-right toggleable"><i class="fa fa-chevron-up"></i></span></legend>',
              '<div class="content"></div>',
            '</fieldset>',
          '</div>',
          '<div class="modal-footer">',
            '<input type="submit" name="submit" value="{{>submit}}" class="btn btn-primary submit">',
          '</div>',
        '</form>'
      ].join(''),
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

  RecipientList.prototype.init = function() {
    var self = this;

    var content = {
      labels: self.options.labels,
      prefix: self.prefixes,
      values: self.values,
    };

    var recipientForId = function(id) {
      for (var i = 0; i < content.values.length; i++) {
        if (content.values[i].id === id)
          return content.values[i];
      }
      return null;
    };

    var updateRecipient = function(id, recipient) {
      for (var i = 0; i < content.values.length; i++) {
        if (content.values[i].id === id) {
          for (var key in recipient) {
            content.values[i][key] = recipient[key];
          }
          return content.values[i];
        }
      }
      content.values.push(recipient);
      return recipient;
    };

    var removeRecipient = function(id) {
      for (var i = 0; i < content.values.length; i++) {
        if (content.values[i].id === id) {
          content.values.splice(i, 1);
          return true;
        }
      }
      return false;
    };

    var tgtnode = self.$el.find(self.targets);
    tgtnode.html([
      '<div class="recipientlist-items"/>',
      '<div class="recipientlist-adder"/>'
    ].join(""));
    var itemhook = tgtnode.find('.recipientlist-items');
    var addhook = tgtnode.find('.recipientlist-adder');
    addhook.html($.templates.adderTemplate.render(content));

    $.each(content.values, function(i, recipient) {
      var data = {
        labels: content.labels,
        prefix: content.prefix,
        values: content.values,
        recipient: recipient,
      };
      itemhook.append($.templates.entryTemplate.render(data));
    });
    itemhook.find('[data-toggle]').tooltip();

    var MODAL_MODE_CREATE = 0;
    var MODAL_MODE_EDIT = 1;
    var show_modal = function(edit_mode, id, recipient) {
      var modal = $('#modal');
      var modalinput = {
        id: id,
        value: recipient.value,
        title: (edit_mode == MODAL_MODE_CREATE) ? content.labels.create : content.labels.edit,
        submit: (edit_mode == MODAL_MODE_CREATE) ? content.labels.add : content.labels.apply,
        labels: content.labels
      };
      var medit = $.templates.editTemplate.render(modalinput);
      modal.find('.modal-content').html(medit);
      var params_list = modal.find('#recipient-params-list');
      var params_data = recipient.params;
      var params_mapping = {};
      $.map(params_data, function(val, key) {
        var ret = {};
        ret["type"] = "string";
        ret["default"] = "";
        ret["longdesc"] = __("User-defined attribute.");
        params_mapping[key] = ret;
      });
      params_list.data('attrlist', params_data);
      params_list.data('attrlist-mapping', params_mapping);
      params_list.attrList();
      var meta_list = modal.find('#recipient-meta-list');
      var meta_data = recipient.meta;
      var metamapping = {};
      metamapping["timeout"] = {
        type: "string",
        longdesc: __("If the alert agent does not complete within this amount of time, it will be terminated."),
      };
      metamapping["timestamp-format"] = {
        type: "string",
        longdesc: __("Format the cluster will use when sending the event’s timestamp to the agent. This is a string as used with the date(1) command."),
      };
      metamapping["timeout"]["default"] = "30s";
      metamapping["timestamp-format"]["default"] = "%H:%M:%S.%06N";
      meta_list.data('attrlist', meta_data);
      meta_list.data('attrlist-mapping', metamapping);
      meta_list.attrList();
      modal.modal('show');
      modal.find('form').submit(function(event) {
        event.preventDefault();

        var values = $(this).serializeArray();
        recipient.params = {};
        recipient.meta = {};
        $.each(values, function(i, item) {
          if (item.name in recipient) {
            recipient[item.name] = item.value;
          } else if (item.name.startsWith("recipient[params]")) {
            recipient.params[item.name.replace(/recipient\[params\]\[(.*)\]/, "$1")] = item.value;
          } else if (item.name.startsWith("recipient[meta]")) {
            recipient.meta[item.name.replace(/recipient\[meta\]\[(.*)\]/, "$1")] = item.value;
          }
        });

        var replacing = false;
        if (recipientForId(id) != null || edit_mode == MODAL_MODE_EDIT) {
          replacing = true;
        }

        var data = {
          labels: content.labels,
          prefix: content.prefix,
          values: content.values,
          recipient: recipient,
        };
        var rendered = $.templates.entryTemplate.render(data);
        if (replacing) {
          itemhook.find('[data-element="' + id + '"]').replaceWith(rendered);
        } else {
          itemhook.append(rendered);
        }
        itemhook.find('[data-toggle]').tooltip();
        updateRecipient(id, recipient);

        modal.modal('hide');
      });
    };

    tgtnode.on('click', '.addition .setter .create', function(e) {
      e.preventDefault();
      show_modal(MODAL_MODE_CREATE, 'alerts-recipient-temporary-id-' + self.create_count, {
        id: 'alerts-recipient-temporary-id-' + self.create_count,
        value: "",
        meta: {},
        params: {},
      });
      self.create_count += 1;
    }).on('click', '.remove', function(e) {
      e.preventDefault();
      var id = $(this).data('entry');
      removeRecipient(id);
      itemhook.find('[data-element="' + id + '"]').remove();
    }).on('click', '.edit', function(e) {
      var id = $(this).data('entry');
      show_modal(MODAL_MODE_EDIT, id, recipientForId(id));
    });
  };

  $.fn.recipientList = function(options) {
    return this.each(function() {
      new RecipientList(this, options);
    });
  };
}(jQuery));

$(function() {
  $('[data-recipients]').recipientList();
});
