// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

;(function($) {
  'use strict';

  function ConstraintList(el, options) {
    this.$el = $(el);

    this.values = this.$el.data('constraints');

    this.targets = this.$el.data('constraints-target');
    this.prefixes = this.$el.data('constraints-prefix');
    this.available = this.$el.data('constraints-available');
    this.selects = this.$el.data('constraints-selects');

    this.defaults = {
      labels: {
        create: __('Create'),
        remove: __('Remove'),

        swaper: __('Swap with entry above'),
        linker: __('Link with entry above'),
        unlink: __('Unlink from entry above'),
      },
      template: [
        '{^{for entries}}',
          '{^{if resources && resources.length > 0}}',
            '<div class="well well-sm">',
              '{^{for resources}}',
                '<div class="form-group">',
                  '<input name="{{>~root.prefix}}[{{>#parent.getIndex()}}][resources][]" type="hidden" data-link="#data" />',
                  '<input name="{{>~root.prefix}}[{{>#parent.getIndex()}}][sequential]" type="hidden" data-link="#parent.parent.data.resources.length > 1 ? \'false\' : \'true\'" />',

                  '<label class="col-sm-5 control-label">',
                    '{{:#data}}',
                  '</label>',

                  '<div class="col-sm-7">',
                    '<div class="input-group">',
                      '<select class="form-control select" name="{{>~root.prefix}}[{{>#parent.getIndex()}}][action]" data-link="#parent.parent.data.action">',
                        '<option></option>',
                        '{^{props ~root.selects}}',
                          '<option value="{{>key}}">',
                            '{{>prop}}',
                          '</option>',
                        '{{/props}}',
                      '</select>',

                      '<div class="input-group-btn">',
                        '{^{if #index === 0}}',
                          '<a href="#" class="linker btn btn-default" data-attr="{{:#data}}" title="{{>~root.linker_label}}">',
                            '<i class="fa fa-link fa-lg fa-fw"></i>',
                          '</a>',
                        '{{else}}',
                          '<a href="#" class="unlink btn btn-default" data-attr="{{:#data}}" title="{{>~root.unlink_label}}">',
                            '<i class="fa fa-cut fa-lg fa-fw"></i>',
                          '</a>',
                        '{{/if}}',
                        '<a href="#" class="swaper btn btn-default" data-attr="{{:#data}}" title="{{>~root.swaper_label}}">',
                          '<i class="fa fa-arrow-up fa-lg fa-fw"></i>',
                        '</a>',
                        '<a href="#" class="remove btn btn-default" data-attr="{{:#data}}" title="{{>~root.remove_label}}">',
                          '<i class="fa fa-minus fa-lg fa-fw"></i>',
                        '</a>',
                      '</div>',
                    '</div>',
                  '</div>',
                '</div>',
              '{{/for}}',
            '</div>',
          '{{/if}}',
        '{{/for}}',

        '<div class="form-group addition" data-link="visible{:remaining.length > 0}">',
          '<div class="col-sm-5 select">',
            '<select class="form-control select" name="temp[selector]">',
              '<option></option>',
              '{^{for remaining}}',
                '<option value="{{:#data}}">',
                  '{{:#data}}',
                '</option>',
              '{{/for}}',
            '</select>',
          '</div>',

          '<div class="col-sm-7 setter">',
            '<div class="input-group">',
              '<select class="form-control select" name="temp[value]">',
                '<option></option>',
                '{^{props selects}}',
                  '<option value="{{>key}}" {{if key === "Started" || key === "start" }} selected="selected" {{/if}}>',
                    '{{>prop}}',
                  '</option>',
                '{{/props}}',
              '</select>',

              '<div class="input-group-btn">',
                '<a href="#" class="create btn btn-default" title="{{>create_label}}">',
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
      constraints: this.options.template
    });

    this.init();
  }

  ConstraintList.prototype.init = function() {
    var self = this;

    $.each(self.values, function(outer, parent) {
      $.each(parent.resources, function(inner, group) {
        if ($.inArray(group, self.available) >= 0) {
          self.available.splice(
            $.inArray(group, self.available),
            1
          );
        }
      });
    });

    var content = {
      create_label: self.options.labels.create,
      remove_label: self.options.labels.remove,
      swaper_label: self.options.labels.swaper,
      linker_label: self.options.labels.linker,
      unlink_label: self.options.labels.unlink,

      prefix: self.prefixes,
      entries: self.values,
      selects: self.selects,
      remaining: self.available
    };

    $.templates.constraints.link(
      self.targets,
      content
    )
      .on('keyup change', 'input, select', function(e) {
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
      })
      .on('click', '.addition .setter .create', function(e) {
        e.preventDefault();

        var key = $(e.currentTarget)
          .parents('.addition')
          .find('.select select').val();

        var value = $(e.currentTarget)
          .parents('.addition')
          .find('.setter select').val();

        if (key) {
          $.observable(
            content['entries']
          ).insert({
            sequential: true,
            action: value,
            resources: [
              key
            ]
          });

          $.observable(
            content['remaining']
          ).remove($.inArray(key, $.view(this).data.remaining));

          $(e.currentTarget)
            .parents('.addition')
            .find('.select select').val(null);

          // Set default value for the target role's select input (after clicking on the plus sign)
          $(e.currentTarget)
            .parents('.addition')
              .find('.setter select option')
                .filter(function(i, e) { return $(e).text() == "Started" || $(e).text() == "Start" })
                  .prop('selected', true);
        }

        self.$el.find('.form-group:first .linker, .form-group:first .unlink, .form-group:first .swaper')
          .addClass('disabled');
      })
      .on('click', '.remove', function(e) {
        e.preventDefault();

        $.observable(
          content['remaining']
        ).insert($.view(this).data);

        $.observable(
          content['entries'][$.view(this).parent.getIndex()]['resources']
        ).remove($.view(this).index);

        self.$el.find('.form-group:first .linker, .form-group:first .unlink, .form-group:first .swaper')
          .addClass('disabled');
      })
      .on('click', '.swaper', function(e) {
        e.preventDefault();

        if ($.view(this).index == 0) {
          $.observable(
            content['entries']
          ).move(
            $.view(this).parent.getIndex(),
            $.view(this).parent.getIndex() - 1
          );

        } else {
          $.observable(
            content['entries'][$.view(this).parent.getIndex()]['resources']
          ).move(
            $.view(this).getIndex(),
            $.view(this).getIndex() - 1
          );
        }

        self.$el.find('.form-group:first .linker, .form-group:first .unlink, .form-group:first .swaper')
          .addClass('disabled');
      })
      .on('click', '.linker', function(e) {
        e.preventDefault();

        $.observable(
          content['entries'][$.view(this).parent.parent.getIndex() - 1]['resources']
        ).insert(
          $.view(this).parent.parent.data
        );

        $.observable(
          content['entries']
        ).remove($.view(this).parent.parent.getIndex());

        self.$el.find('.form-group:first .linker, .form-group:first .unlink, .form-group:first .swaper')
          .addClass('disabled');
      })
      .on('click', '.unlink', function(e) {
        e.preventDefault();

        $.observable(
          content['entries']
        ).insert(
          $.view(this).parent.parent.getIndex() + 1,
          {
            sequential: true,
            action: $.view(this).parent.parent.parent.data.action,
            resources: [
              $.view(this).parent.data
            ]
          }
        );

        $.observable(
          content['entries'][$.view(this).parent.parent.getIndex()]['resources']
        ).remove($.view(this).getIndex());

        self.$el.find('.form-group:first .linker, .form-group:first .unlink, .form-group:first .swaper')
          .addClass('disabled');
      });

      self.$el.find('.form-group:first .linker, .form-group:first .unlink, .form-group:first .swaper')
        .addClass('disabled');
  };

  $.fn.constraintList = function(options) {
    return this.each(function() {
      new ConstraintList(this, options);
    });
  };
}(jQuery));

$(function() {
  $('[data-constraints]').constraintList();
});
