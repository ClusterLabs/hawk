// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

;(function($) {
  'use strict';

  function WizAttrList(el, options) {
    this.$el = $(el);

    this.values = this.$el.data('wizattrlist');
    this.targets = this.$el.data('wizattrlist-target');
    this.mapping = this.$el.data('wizattrlist-mapping');

    this.available = $.map(this.mapping, function(values, id) {
      return { "id": id, "name": values.name };
    });

    this.defaults = {
      labels: {
        create: __('Create'),
        remove: __('Remove'),
        trueish: __('Yes'),
        falseish: __('No')
      },

      selectEnum: [
        '<select class="form-control select" name="{{>key}}" id="{{>key}}">',
        '<option></option>',
        '{{for mapping[key]["values"]}}',
        '<option value="{{:#data}}" {{if #data == value}}selected{{/if}}>',
        '{{:#data}}',
        '</option>',
        '{{/for}}',
        '</select>',
      ].join(''),

      selectBoolean: [
        '<select class="form-control select" name="{{>key}}" id="{{>key}}">',
        '<option value="true">',
        '{{>labels.trueish}}',
        '</option>',
        '<option value="false">',
        '{{>labels.falseish}}',
        '</option>',
        '</select>',
      ].join(''),

      selectInteger: '<input class="form-control text-field" type="number" name="{{>key}}" value="{{>mapping[key]["default"]}}" id="{{>key}}" />',

      selectOther: '<input class="form-control text-field" type="text" name="{{>key}}" value="{{>mapping[key]["default"]}}" id="{{>key}}" />',

      selectByType: [
        '{{if mapping[key].type == "enum"}}',
          '{{include tmpl="selectEnum" /}}',
        '{{else mapping[key].type == "boolean"}}',
           '{{include tmpl="selectBoolean" /}}',
        '{{else mapping[key].type == "integer"}}',
           '{{include tmpl="selectInteger" /}}',
        '{{else}}',
           '{{include tmpl="selectOther" /}}',
        '{{/if}}',
      ].join(''),

      // arguments:
      // key = param id
      // mapping
      // labels
      entryTemplate: [
        '<div class="form-group" data-element="{{>key}}" data-help-filter=".{{>mapping[key].help_id}}">',
          '<label class="col-sm-5 control-label" for="{{>key}}">',
            '{{>mapping[key].name}}',
          '</label>',
          '<div class="col-sm-7">',
            '<div class="input-group">',
              '{{include tmpl="selectByType" /}}',
              '<div class="input-group-btn">',
                '<a class="remove btn btn-default" title="{{>labels.remove}}" data-attr="{{>key}}"><i class="fa fa-minus fa-lg fa-fw"></i></a>',
              '</div>',
            '</div>',
          '</div>',
        '</div>'
      ].join(''),

      // arguments:
      // available = [{id, name}]
      // labels
      adderTemplate: [
        '<div class="form-group addition">',
          '<div class="col-sm-5">',
          '</div>',

          '<div class="col-sm-7 setter">',
            '<div class="input-group">',
              '<select class="form-control select ignore" name="temp[selector]">',
                '<option></option>',
                '{{for available}}',
                  '<option value="{{>id}}">',
                    '{{>name}}',
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
      ].join('')
    };

    this.options = $.extend(
      this.defaults,
      options
    );

    $.templates({
      entryTemplate: this.options.entryTemplate,
      adderTemplate: this.options.adderTemplate,
      selectByType: this.options.selectByType,
      selectEnum: this.options.selectEnum,
      selectBoolean: this.options.selectBoolean,
      selectInteger: this.options.selectInteger,
      selectOther: this.options.selectOther
    });

    this.init();
  }

  WizAttrList.prototype.init = function() {
    var self = this;

    $.each(Object.keys(self.values), function(index, value) {
      var found = null;
      $.each(self.available, function(at, item) {
        if (item.id == value)
          found = at;
      });
      if (found !== null && found.length > 0) {
        self.available.splice(found, 1);
      }
    });

    self.available.sort(function(a, b) { return a.name.localeCompare(b.name); });

    var content = {
      labels: self.options.labels,
      mapping: self.mapping,
      available: self.available,
      values: self.values,
      key: ''
    };

    var tgtnode = self.$el.find(self.targets);
    tgtnode.html($.templates.adderTemplate.render(content));

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

      if (id.length == 0)
        return;

      content.key = id;

      // 1. remove from available
      $.each(self.available, function(at, item) {
        if (item.id == id) {
          $(this).remove();
        }
      });

      // 2. add to entries

      content.values[id] = content.mapping[id]["default"];
      tgtnode.find('.addition').before($.templates.entryTemplate.render(content));
      tgtnode.find('[data-element="' + id + '"]').each(function() {
        $(this).find('select, input').val(content.mapping[id]["default"]);
      });

      // 3. re-render the select
      var toremove = 'option[value="' + id + '"]';
      tgtnode.find('.setter select').find('option:selected').remove();

    }).on('click', '.remove', function(e) {
      e.preventDefault();
      var id = $(this).data('attr');

      // 1. remove from entries
      tgtnode.find('[data-element="' + id + '"]').remove();

      // 2. add to available
      self.available.push({id: id, name: self.mapping[id].name});
      self.available.sort(function(a, b) { return a.name.localeCompare(b.name); });

      // 3. re-render the select
      var adder = tgtnode.find('.setter select');
      adder.append('<option value="' + id + '">' + self.mapping[id].name + '</option>');
      var new_options = adder.find('option');
      new_options.sort(function(a, b) { return a.text.localeCompare(b.text); });
      adder.empty().append(new_options).val('');

    }).on('change', '.setter select', function(e) {
      var val = $(this).val();
      if (val && content.mapping[val]) {
        var filter = "." + content.mapping[val].help_id;
        tgtnode.find('.setter').attr("data-help-filter", filter);
        $('[data-help-target]').each(function() {
          $($(this).data('help-target')).hide().filter(filter).show();
        });
      } else {
        tgtnode.find('.setter').removeAttr("data-help-filter");
      }
    });

    // add the initial values
    $.each(content.values, function(key, value) {
      content.key = key;

      // 1. remove from available
      $.each(self.available, function(at, item) {
        if (item.id == key) {
          $(this).remove();
        }
      });

      // 2. add to entries
      tgtnode.find('.addition').before($.templates.entryTemplate.render(content));
      tgtnode.find('[data-element="' + key + '"]').each(function() {
        $(this).find('select, input').val(value);
      });
    });
  };

  $.fn.wizAttrList = function(options) {
    return this.each(function() {
      new WizAttrList(this, options);
    });
  };
}(jQuery));

$(function() {
  $('[data-wizattrlist]').wizAttrList();
});
