;(function($) {
  'use strict';

  function AttrList(el, options) {
    this.$el = $(el);

    this.values = this.$el.data('attrlist');

    this.targets = this.$el.data('attrlist-target');
    this.prefixes = this.$el.data('attrlist-prefix');
    this.mapping = this.$el.data('attrlist-mapping');

    this.result = {};

    this.defaults = {
      labels: {
        remove: __('Remove')
      },
      templates: {
        removeButton: [
          '<a href="#" class="remove" title="{{>label}}" data-attr="{{>key}}">',
            '<i class="fa fa-minus fa-lg"></i>',
          '</a>'
        ].join(''),
        createButton: [
          '<a href="#" class="create" title="{{>label}}">',
            '<i class="fa fa-plus fa-lg"></i>',
          '</a>'
        ].join(''),
        formRow: [
          '<div class="form-group" data-help-filter=".row.{{>key}}">',
            '<label class="col-sm-5 control-label" for="{{>key}}">',
              '{{>key}}',
            '</label>',
            '<div class="col-sm-7">',
              '<div class="input-group">',
                '{{:input}}',
                '<div class="input-group-addon">',
                  '{{:button}}',
                '</div>',
              '</div>',
            '</div>',
          '</div>'
        ].join(''),
        createRow: [
          '<div class="form-group addition">',
            '<div class="col-sm-5 select">',
              '{{:key}}',
            '</div>',
            '<div class="col-sm-7 setter">',
              '<div class="input-group">',
                '{{:input}}',
                '<div class="input-group-addon">',
                  '{{:button}}',
                '</div>',
              '</div>',
            '</div>',
          '</div>'
        ].join(''),
        optionInput: [
          '<option{{if value}} value="{{>value}}"{{/if}}{{if selected}} selected="selected"{{/if}}>',
            '{{>key}}',
          '</option>'
        ].join(''),
        enumInput: [
          '<select class="form-control select" name="{{>prefix}}[{{>key}}]" id="{{>key}}">',
            '{{:options}}',
          '</select>'
        ].join(''),
        defaultInput: '<input class="form-control text-field" type="{{>type}}" name="{{>prefix}}[{{>key}}]" value="{{>value}}" id="{{>key}}" />'
      }
    };

    this.options = $.extend(
      this.defaults,
      options
    );

    $.templates({
      removeButton: this.options.templates.removeButton,
      createButton: this.options.templates.createButton,
      formRow: this.options.templates.formRow,
      createRow: this.options.templates.createRow,
      optionInput: this.options.templates.optionInput,
      enumInput: this.options.templates.enumInput,
      defaultInput: this.options.templates.defaultInput
    });

    this.init();
  }

  AttrList.prototype.init = function() {
    var self = this;

    $.each(self.values, function(key, value) {
      self.generateRow(
        key,
        value
      );
    });

    $(
      self.$el.find(self.targets)
    ).on('change', '.addition .select select', function(e) {
      e.preventDefault();

      var key = $(e.currentTarget).val();
      var value = self.mapping[key]['default'];

      $(e.currentTarget)
        .parents('.addition')
        .find('.setter input, .setter select')
        .replaceWith(self.buildInput(key, value));
    });

    $(
      self.$el.find(self.targets)
    ).on('click', '.addition .setter .create', function(e) {
      e.preventDefault();

      var key = $(e.currentTarget)
        .parents('.addition')
        .find('.select select').val();

      var value = $(e.currentTarget)
        .parents('.addition')
        .find('.setter input, .setter select').val();

      self.writeValue(key, value);
    });

    $(
      self.$el.find(self.targets)
    ).on('click', '.remove', function(e) {
      e.preventDefault();

      delete self.result[
        $(e.currentTarget).data('attr')
      ];

      delete self.values[
        $(e.currentTarget).data('attr')
      ];

      self.writeOutput();
    });

    self.writeOutput();
  };

  AttrList.prototype.buildEnum = function(key, value) {
    var self = this;

    return $.render.enumInput({
      prefix: self.prefixes,
      key: key,
      options: $.map(self.mapping[key]['values'], function(v, k) {
        return $.render.optionInput({
          key: v,
          value: v,
          selected: value === v
        });
      })
    });
  };

  AttrList.prototype.buildBoolean = function(key, value) {
    var self = this;

    return $.render.enumInput({
      prefix: self.prefixes,
      key: key,
      options: [
        $.render.optionInput({
          key:  __('Yes'),
          value: 'true',
          selected: value === 'true'
        }),
        $.render.optionInput({
          key: __('No'),
          value: 'false',
          selected: value === 'false'
        })
      ]
    });
  };

  AttrList.prototype.buildInteger = function(key, value) {
    var self = this;

    return $.render.defaultInput({
      prefix: self.prefixes,
      key: key,
      value: value,
      type: 'number'
    });
  };

  AttrList.prototype.buildDefault = function(key, value) {
    var self = this;

    return $.render.defaultInput({
      prefix: self.prefixes,
      key: key,
      value: value,
      type: 'text'
    });
  };

  AttrList.prototype.buildInput = function(key, value) {
    var self = this;

    switch (self.mapping[key]['type']) {
      case 'enum':
        return self.buildEnum(key, value);
        break;

      case 'boolean':
        return self.buildBoolean(key, value);
        break;

      case 'integer':
        return self.buildInteger(key, value);
        break;

      default:
        return self.buildDefault(key, value);
        break;
    }
  };

  AttrList.prototype.writeValue = function(key, value) {
    var self = this;

    self.values[key] = value;
    self.generateRow(key, value);
    self.writeOutput();
  };

  AttrList.prototype.generateRow = function(key, value) {
    var self = this;

    self.result[key] = $.render.formRow({
      key: key,
      input: self.buildInput(key, value),
      button: $.render.removeButton({
        key: key,
        label: self.options.labels.remove
      })
    });
  };

  AttrList.prototype.generateSelector = function() {
    var self = this;

    var selects = [
      $.render.optionInput({
        key: '',
        selected: false
      })
    ];

    $.each(Object.keys(self.mapping).sort(), function(i, k) {
      if (!self.values.hasOwnProperty(k)) {
        selects.push(
          $.render.optionInput({
            key: k,
            value: k,
            selected: false
          })
        );
      }
    });

    if (selects.length > 1) {
      return $.render.createRow({
        key: $.render.enumInput({
          prefix: 'temp',
          key: 'selector',
          options: selects.join('')
        }),
        input: $.render.defaultInput({
          prefix: 'temp',
          key: 'value',
          value: '',
          type: 'text'
        }),
        button: $.render.createButton({
          label: self.options.labels.create
        })
      });
    } else {
      return ''
    }
  };

  AttrList.prototype.writeOutput = function() {
    var self = this;

    var temp = $.map(
      self.result,
      function(v, k) {
        return v;
      }
    );

    temp.push(
      self.generateSelector()
    );

    this.$el.find(self.targets).html(
      temp.join('')
    );
  };

  $.fn.attrList = function(options) {
    return this.each(function() {
      new AttrList(this, options);
    });
  };
}(jQuery));
