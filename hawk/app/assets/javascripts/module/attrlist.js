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

  function AttrList(el, options) {
    this.$el = $(el);

    this.values = this.$el.data('attrlist');

    this.targets = this.$el.data('attrlist-target');
    this.prefixes = this.$el.data('attrlist-prefix');
    this.mapping = this.$el.data('attrlist-mapping');

    this.available = Object.keys(this.mapping);

    this.defaults = {
      labels: {
        create: __('Create'),
        remove: __('Remove'),
        trueish: __('Yes'),
        falseish: __('No')
      },
      template: [
        '{^{props entries}}',
          '<div class="form-group" data-help-filter=".row.{{>key}}">',
            '<label class="col-sm-5 control-label" for="{{>key}}">',
              '{{>key}}',
            '</label>',

            '<div class="col-sm-7">',
              '<div class="input-group">',
                '{^{if #parent.parent.data.mapping[key]["type"] == "enum"}}',
                  '<select class="form-control select" name="{{>#parent.parent.parent.data.prefix}}[{{>key}}]" id="{{>key}}" data-link="prop">',
                    '<option></option>',
                    '{^{for #parent.parent.parent.data.mapping[key]["values"]}}',
                      '<option value="{{:#data}}">',
                        '{{:#data}}',
                      '</option>',
                    '{{/for}}',
                  '</select>',
                '{{else #parent.parent.data.mapping[key]["type"] == "boolean"}}',
                  '<select class="form-control select" name="{{>#parent.parent.parent.data.prefix}}[{{>key}}]" id="{{>key}}" data-link="prop">',
                    '<option value="true">',
                      '{{>#parent.parent.parent.data.true_label}}',
                    '</option>',
                    '<option value="false">',
                      '{{>#parent.parent.parent.data.false_label}}',
                    '</option>',
                  '</select>',
                '{{else #parent.parent.data.mapping[key]["type"] == "integer"}}',
                  '<input class="form-control text-field" type="number" name="{{>#parent.parent.parent.data.prefix}}[{{>key}}]" value="{{>prop}}" id="{{>key}}" />',
                '{{else}}',
                  '<input class="form-control text-field" type="text" name="{{>#parent.parent.parent.data.prefix}}[{{>key}}]" value="{{>prop}}" id="{{>key}}" />',
                '{{/if}}',

                '<div class="input-group-btn">',
                  '<a href="#" class="remove btn btn-default" data-attr="{{:#data}}" title="{{>#parent.data.remove_label}}">',
                    '<i class="fa fa-minus fa-lg fa-fw"></i>',
                  '</a>',
                '</div>',
              '</div>',
            '</div>',
          '</div>',
        '{{/props}}',

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
              '{^{if select == \'disabled\'}}',
                '<input class="form-control text-field" type="number" name="temp[value]" value="" disabled="disabled" />',
              '{{else select != \'disabled\' && mapping[select][\'type\'] == \'enum\'}}',
                '<select class="form-control select" name="temp[value]" data-link="mapping[select][\'default\']">',
                  '<option></option>',
                  '{^{for #parent.data.mapping[select][\'values\']}}',
                    '<option value="{{:#data}}">',
                      '{{:#data}}',
                    '</option>',
                  '{{/for}}',
                '</select>',
              '{{else select != \'disabled\' && mapping[select][\'type\'] == \'boolean\'}}',
                '<select class="form-control select" name="temp[value]" data-link="mapping[select][\'default\']">',
                  '<option value="true">',
                    '{{>#parent.data.true_label}}',
                  '</option>',
                  '<option value="false">',
                    '{{>#parent.data.false_label}}',
                  '</option>',
                '</select>',
              '{{else select != \'disabled\' && mapping[select][\'type\'] == \'integer\'}}',
                '<input class="form-control text-field" type="number" name="temp[value]" data-link="mapping[select][\'default\']" />',
              '{{else}}',
                '<input class="form-control text-field" type="text" name="temp[value]" data-link="mapping[select][\'default\']" />',
              '{{/if}}',

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

  AttrList.prototype.init = function() {
    var self = this;

    $.each(Object.keys(self.values), function(index, value) {
      if ($.inArray(value, self.available) >= 0) {
        self.available.splice(
          $.inArray(value, self.available),
          1
        );
      }
    });

    self.available.sort();

    var content = {
      create_label: self.options.labels.create,
      remove_label: self.options.labels.remove,
      true_label: self.options.labels.trueish,
      false_label: self.options.labels.falseish,

      prefix: self.prefixes,
      entries: self.values,
      mapping: self.mapping,
      remaining: self.available,
      select: 'disabled'
    };

    $.templates.constraints.link(
      self.$el.find(self.targets),
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
          .find('.setter .form-control').val();

        if (key !== '') {
          $.observable(
            content['entries']
          ).setProperty(
            key,
            value || ''
          );

          $.observable(
            content['remaining']
          ).remove(
            $.inArray(
              key,
              $.view(this).data.remaining
            )
          );

          $(e.currentTarget)
            .parents('.addition')
            .find('.select select').val(null);

          $(e.currentTarget)
            .parents('.addition')
            .find('.setter .form-control').val(null);

          $.observable(
            content
          ).setProperty(
            'select',
            'disabled'
          );
        }
      })
      .on('click', '.remove', function(e) {
        e.preventDefault();

        $.observable(
          content['remaining']
        ).insert(
          $.view(this).data.key
        );

        $.observable(
          content['remaining']
        ).refresh(
          content['remaining'].sort()
        );

        $.observable(
          content['entries']
        ).removeProperty(
          $.view(this).data.key
        );
      })
      .on('change', '.select select', function(e) {
        $.observable(
          content
        ).setProperty(
          'select',
          $(e.currentTarget).val()
        );
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
