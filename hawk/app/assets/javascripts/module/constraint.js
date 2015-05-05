//======================================================================
//                        HA Web Konsole (Hawk)
// --------------------------------------------------------------------
//            A web-based GUI for managing and monitoring the
//          Pacemaker High-Availability cluster resource manager
//
// Copyright (c) 2009-2013 SUSE LLC, All Rights Reserved.
//
// Author: Tim Serong <tserong@suse.com>
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

;(function($) {
  'use strict';

  function ConstraintList(el, options) {
    this.$el = $(el);

    this.values = this.$el.data('constraints');

    this.targets = this.$el.data('constraints-target');
    this.prefixes = this.$el.data('constraints-prefix');
    this.available = this.$el.data('constraints-available');
    this.selects = this.$el.data('constraints-selects');

    this.mapper = {};
    this.result = [];

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
                  '<input name="{{>#parent.parent.parent.parent.parent.data.prefix}}[{{>#parent.getIndex()}}][resources][]" type="hidden" data-link="#data" />',
                  '<input name="{{>#parent.parent.parent.parent.parent.data.prefix}}[{{>#parent.getIndex()}}][sequential]" type="hidden" data-link="#parent.parent.data.resources.length > 1 ? \'false\' : \'true\'" />',

                  '<label class="col-sm-5 control-label">',
                    '{{:#data}}',
                  '</label>',

                  '<div class="col-sm-7">',
                    '<div class="input-group">',
                      '<select class="form-control select" name="{{>#parent.parent.parent.parent.parent.data.prefix}}[{{>#parent.getIndex()}}][action]" data-link="#parent.parent.data.action">',
                        '<option></option>',
                        '{^{props #parent.parent.parent.parent.parent.data.selects}}',
                          '<option value="{{>key}}">',
                            '{{>prop}}',
                          '</option>',
                        '{{/props}}',
                      '</select>',

                      '<div class="input-group-btn">',
                        '{^{if #index === 0}}',
                          '<a href="#" class="linker btn btn-default" data-attr="{{:#data}}" title="{{>#parent.parent.parent.parent.parent.parent.data.linker_label}}">',
                            '<i class="fa fa-link fa-lg fa-fw"></i>',
                          '</a>',
                        '{{else}}',
                          '<a href="#" class="unlink btn btn-default" data-attr="{{:#data}}" title="{{>#parent.parent.parent.parent.parent.parent.data.unlink_label}}">',
                            '<i class="fa fa-cut fa-lg fa-fw"></i>',
                          '</a>',
                        '{{/if}}',
                        '<a href="#" class="swaper btn btn-default" data-attr="{{:#data}}" title="{{>#parent.parent.parent.parent.parent.data.swaper_label}}">',
                          '<i class="fa fa-arrow-up fa-lg fa-fw"></i>',
                        '</a>',
                        '<a href="#" class="remove btn btn-default" data-attr="{{:#data}}" title="{{>#parent.parent.parent.parent.parent.data.remove_label}}">',
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
                  '<option value="{{>key}}">',
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

          $(e.currentTarget)
            .parents('.addition')
            .find('.setter select').val(null);
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

      // TODO(must): Recalculate remaining

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
