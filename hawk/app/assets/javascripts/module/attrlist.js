// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

;(function($) {
  'use strict';

  function AttrList(el, options) {
    this.$el = $(el);

    this.values = this.$el.data('attrlist');

    this.targets = this.$el.data('attrlist-target');
    this.prefixes = this.$el.data('attrlist-prefix');
    this.mapping = this.$el.data('attrlist-mapping');
    this.freeform = this.$el.data('attrlist-freeform') == 'yes';

    this.available = Object.keys(this.mapping).filter(function(attr) {
      return !attr.match(/jQuery\d+/);
     });


    this.defaults = {
      labels: {
        create: __('Create'),
        remove: __('Remove'),
        trueish: __('Yes'),
        falseish: __('No')
      },
      template: [
        '{^{props entries}}',
          '{^{if ~root.mapping[key]}}',
            '<div class="form-group" data-help-filter=".row.{{>key}}">',
              '<label class="col-sm-5 control-label" for="{{>key}}">',
                '{{>key}}',
              '</label>',

              '<div class="col-sm-7">',
                '<div class="input-group">',
                  '{^{if ~root.mapping[key]["type"] == "enum"}}',
                    '<select class="form-control select" name="{{>~root.prefix}}[{{>key}}]" id="{{>key}}" data-link="prop">',
                      '<option></option>',
                      '{^{for ~root.mapping[key]["values"]}}',
                        '<option value="{{:#data}}">',
                          '{{:#data}}',
                        '</option>',
                      '{{/for}}',
                    '</select>',
                  '{{else ~root.mapping[key]["type"] == "boolean"}}',
                    '<select class="form-control select" name="{{>~root.prefix}}[{{>key}}]" id="{{>key}}" data-link="prop">',
                      '<option value="true">',
                        '{{>~root.true_label}}',
                      '</option>',
                      '<option value="false">',
                        '{{>~root.false_label}}',
                      '</option>',
                    '</select>',
                  '{{else ~root.mapping[key]["type"] == "integer"}}',
                    '<input class="form-control text-field" type="number" name="{{>~root.prefix}}[{{>key}}]" value="{{>prop}}" id="{{>key}}" />',
                  '{{else}}',
                    '<input class="form-control text-field" type="text" name="{{>~root.prefix}}[{{>key}}]" value="{{>prop}}" id="{{>key}}" />',
                  '{{/if}}',

                  '<div class="input-group-btn">',
                    '{{if ~root.mapping[key]["required"] == "1"}}',
                      '<a href="#" class="remove btn btn-default disabled", data-attr="{{:#data}}" title="{{>~root.remove_label}}">',
                    '{{else}}',
                      '<a href="#" class="remove btn btn-default", data-attr="{{:#data}}" title="{{>~root.remove_label}}">',
                    '{{/if}}',
                      '<i class="fa fa-minus fa-lg fa-fw"></i>',
                    '</a>',
                  '</div>',
                '</div>',
              '</div>',
            '</div>',
          '{{/if}}',
        '{{/props}}',
        '{{if ~root.freeform}}',
          '<div class="form-group addition">',
            '<div class="col-sm-offset-5 col-sm-7 select">',
              '<div class="input-group">',
                '<input class="form-control newentry" type="text" name="temp_{{>~root.prefix}}" />',
                '<div class="input-group-btn">',
                  '<a href="#" class="create btn btn-default " title="{{>create_label}}">',
                    '<i class="fa fa-plus fa-lg fa-fw"></i>',
                  '</a>',
                '</div>',
              '</div>',
            '</div>',
          '</div>',
        '{{else}}',
          '<div class="form-group addition" data-link="visible{:remaining.length > 0}">',
            '<div class="col-sm-offset-5 col-sm-7 select">',
              '<div class="input-group">',
                '<select class="form-control newentry" name="temp_{{>~root.prefix}}">',
                  '<option></option>',
                  '{^{for remaining}}',
                    '<option value="{{:#data}}">',
                      '{{:#data}}',
                    '</option>',
                  '{{/for}}',
                '</select>',
                '<div class="input-group-btn">',
                  '<a href="#" class="create btn btn-default " title="{{>create_label}}">',
                    '<i class="fa fa-plus fa-lg fa-fw"></i>',
                  '</a>',
                '</div>',
              '</div>',
            '</div>',
          '</div>',
        '{{/if}}'
      ].join('')
    };

    this.options = $.extend(
      this.defaults,
      options
    );

    $.templates({
      constraints: this.options.template
    });

    this.init();
  }

  AttrList.prototype.init = function() {
    var self = this;

    if (!self.freeform) {
      $.each(Object.keys(self.values), function(index, value) {
        if ($.inArray(value, self.available) >= 0) {
          self.available.splice($.inArray(value, self.available), 1);
        }
      });
      self.available.sort();
    }

    var _values = self.values;
    // for multi-monitor in m/s resource
    if (self.values instanceof Array) {
      _values = self.values[0];
    }
    var content = {
      create_label: self.options.labels.create,
      remove_label: self.options.labels.remove,
      true_label: self.options.labels.trueish,
      false_label: self.options.labels.falseish,

      prefix: self.prefixes,
      entries: _values,
      mapping: self.mapping,
      remaining: self.available,
      select: 'disabled',
      freeform: self.freeform
    };

    $.templates.constraints.link(
      self.$el.find(self.targets),
      content
    )
      .on('keyup change', 'input, select', function(e) {
        // Trigger the plus sign programmatically
        // if the sibling element is a select
        if (e.currentTarget.tagName == "SELECT") {
          $('.addition .select .create').click();
        }
        $(e.delegateTarget)
          .parents('form')
            .find('[name="revert"]')
              .show()
              .end()
            .find('a.back')
              .attr('data-confirm', __('Any changes will be lost - do you wish to proceed?'))
              .end();
      })
      .on('click', '.addition .select .create', function(e) {
        e.preventDefault();

        var key = $(e.currentTarget).parents('.addition').find('.select .newentry').val();
        console.log("add key:", key);

        if (key !== '') {
          if (!(key in self.mapping)) {
            self.mapping[key] = {
              longdesc: ''
            };
            self.mapping[key]["default"] = "";
          }

          var defval = '';
          if (key in self.mapping && 'default' in self.mapping[key]) {
            defval = self.mapping[key]['default'] || '';
          }
          $.observable(content['entries']).setProperty(key, defval);

          if (!self.freeform) {
            $.observable(content['remaining']).remove($.inArray(key, $.view(this).data.remaining));
          }

          $(e.currentTarget).parents('.addition').find('.select .newentry').val(null);

          $.observable(content).setProperty('select', 'disabled');
        }
      })
      .on('click', '.remove', function(e) {
        e.preventDefault();

        if (!self.freeform) {
          $.observable(content['remaining']).insert($.view(this).data.key);
          $.observable(content['remaining']).refresh(content['remaining'].sort());
        }
        $.observable(content['entries']) .removeProperty($.view(this).data.key);
      })
      .on('change', '.select .newentry', function(e) {
        $.observable(content).setProperty('select', $(e.currentTarget).val());
      });
  };

  $.fn.attrList = function(options) {
    return this.each(function() {
      new AttrList(this, options);
    });
  };
}(jQuery));

$(function() {
  $('[data-attrlist]').attrList();
});
