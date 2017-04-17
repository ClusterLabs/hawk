// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

;(function($) {
  'use strict';

  function rulesList(el, options) {
    this.$el = $(el);

    this.values = this.$el.data('locations');
    this.targets = this.$el.data('locations-target');
    this.prefixes = this.$el.data('locations-prefix');

    this.defaults = {
      labels: {
        create: __('Create'),
        remove: __('Remove'),
      },
      template: [
        '{^{for entries}}',
          '<fieldset>',
            '<legend>',
              __('Rule'),

              '<div class="pull-right">',
                '<i class="fa fa-plus rule add"></i> ',
                '<i class="fa fa-minus rule remove"></i>',
              '</div>',
            '</legend>',

            '<div class="form-group" data-help-filter=".row.score">',
              '<label class="col-sm-5 control-label">',
                __('Score'),
              '</label>',
              '<div class="col-sm-7">',
                '<input class="form-control text-field" type="text" name="{{>~root.prefix}}[{{>#getIndex()}}][score]" data-link="score" />',
              '</div>',
            '</div>',
            '<div class="form-group" data-help-filter=".row.role">',
              '<label class="col-sm-5 control-label">',
                __('Role'),
              '</label>',
              '<div class="col-sm-7">',
                '<select class="form-control select" name="{{>~root.prefix}}[{{>#getIndex()}}][role]" data-link="role">',
                  '<option value=""></option>',
                  '<option value="Started">Started</option>',
                  '<option value="Master">Master</option>',
                  '<option value="Slave">Slave</option>',
                '</select>',
              '</div>',
            '</div>',
            '<div class="form-group" data-help-filter=".row.operator">',
              '<label class="col-sm-5 control-label">',
                __('Boolean Operator'),
              '</label>',
              '<div class="col-sm-7">',
                '<select class="form-control select" name="{{>~root.prefix}}[{{>#getIndex()}}][operator]" data-link="operator">',
                  '<option value="and" selected>and</option>',
                  '<option value="or">or</option>',
                '</select>',
              '</div>',
            '</div>',

            '<div class="well">',
              '<legend>',
                'Expressions',
              '</legend>',

              '{^{for expressions}}',
                '<div class="form-group" data-help-filter=".row.expression">',
                  '{^{if kind == "attr-def"}}',
                    '<div class="col-sm-5">',
                      '<input class="form-control text-field input-sm" type="text" name="{{>~root.prefix}}[{{>#parent.parent.getIndex()}}][expressions][{{>#parent.getIndex()}}][attribute]" data-link="attribute" />',
                    '</div>',

                    '<div class="col-sm-7">',
                      '<div class="input-group input-group-sm">',
                        '<select class="form-control select" name="{{>~root.prefix}}[{{>#parent.parent.getIndex()}}][expressions][{{>#parent.getIndex()}}][operation]" data-link="operation">',
                          '<option value="defined">is defined</option>',
                          '<option value="not_defined">is not defined</option>',
                        '</select>',
                        '<div class="input-group-btn">',
                          '<a href="#" class="expression remove btn btn-default">',
                            '<i class="fa fa-minus fa-sm fa-fw"></i>',
                          '</a>',
                        '</div>',
                      '</div>',
                    '</div>',

                  '{^{else}}',
                    '<div class="col-sm-5">',
                      '<div class="input-group input-group-sm">',
                        '<input class="form-control text-field" type="text" name="{{>~root.prefix}}[{{>#parent.parent.getIndex()}}][expressions][{{>#parent.getIndex()}}][attribute]" data-link="attribute" />',
                        '<span class="input-group-btn">',
                          '<select class="btn btn-default" name="{{>~root.prefix}}[{{>#parent.parent.getIndex()}}][expressions][{{>#parent.getIndex()}}][operation]" data-link="operation">',
                            '<option value="eq">=</option>',
                            '<option value="ne">≠</option>',
                            '<option value="lt">&lt;</option>',
                            '<option value="lte">≤</option>',
                            '<option value="gte">≥</option>',
                            '<option value="gt">&gt;</option>',
                          '</select>',
                        '</span>',
                      '</div>',
                    '</div>',

                    '<div class="col-sm-7">',
                      '<div class="input-group input-group-sm">',
                        '<input class="form-control text-field" type="text" name="{{>~root.prefix}}[{{>#parent.parent.getIndex()}}][expressions][{{>#parent.getIndex()}}][value]" data-link="value" />',
                        '<span class="input-group-btn">',
                          '<select class="btn btn-default" name="{{>~root.prefix}}[{{>#parent.parent.getIndex()}}][expressions][{{>#parent.getIndex()}}][type]" data-link="type">',
                            '<option value=""></option>',
                            '<option value="string">String</option>',
                            '<option value="integer">Integer</option>',
                            '<option value="version">Version</option>',
                          '</select>',
                        '</span>',
                        '<div class="input-group-btn">',
                          '<a href="#" class="expression remove btn btn-default">',
                            '<i class="fa fa-minus fa-sm fa-fw"></i>',
                          '</a>',
                        '</div>',
                      '</div>',
                    '</div>',
                  '{{/if}}',
                '</div>',
              '{{/for}}',

              '<div class="form-group addition">',
                '<div class="col-sm-7 col-sm-offset-5">',
                  '<div class="input-group input-group-sm">',
                    '<select class="form-control select">',
                      '<option value=""></option>',
                      '<option value="uname">#uname</option>',
                      '<option value="attr-val">[attribute] = [value]</option>',
                      '<option value="attr-def">[attribute] defined</option>',
                    '</select>',
                    '<div class="input-group-btn">',
                      '<a href="#" class="create btn btn-default">',
                        '<i class="fa fa-plus fa-sm fa-fw"></i>',
                      '</a>',
                    '</div>',
                  '</div>',
                '</div>',
              '</div>',
            '</div>',
          '</fieldset>',
        '{{/for}}',
        '<fieldset>',
          '<legend>',
            __('New Rule'),
            '<div class="pull-right">',
              '<i class="fa fa-plus rule new"></i> ',
            '</div>',
          '</legend>',
        '</fieldset>',
      ].join('')
    };

    this.options = $.extend(
      this.defaults,
      options
    );

    $.templates({
      locations: this.options.template
    });

    this.init();
  }

  rulesList.prototype.init = function() {
    var self = this;

    var content = {
      prefix: self.prefixes,
      entries: self.values
    };

    $.templates.locations.link(
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
      .on('click', '.addition .create', function(e) {
        e.preventDefault();

        var selection = $(e.currentTarget)
          .parents('.addition')
          .find('select').val();

        if (selection) {
          $.observable(
            content['entries'][$.view(this).index]['expressions']
          ).insert({
            operation: selection == 'attr-def' ? 'defined' : 'eq',
            attribute: selection == 'uname' ? '#uname' : '',
            kind: selection
          });

          $(e.currentTarget)
            .parents('.addition')
            .find('select').val(null);
        }
      })
      .on('click', '.rule.add', function(e) {
        e.preventDefault();

        $.observable(
          content['entries']
        ).insert($.view(this).index + 1, {
          score: 'INFINITY',
          role: '',
          operator: 'and',
          expressions: []
        });
      })
      .on('click', '.rule.new', function(e) {
        e.preventDefault();

        $.observable(
          content['entries']
        ).insert(content['entries'].length, {
            score: '-INFINITY',
            role: '',
            operator: '',
            expressions: []
          });
      })
      .on('click', '.rule.remove', function(e) {
        e.preventDefault();

        $.observable(
          content['entries']
        ).remove($.view(this).index);
      })
      .on('click', '.expression.remove', function(e) {
        e.preventDefault();

        $.observable(
          content['entries'][$.view(this).parent.parent.getIndex()]['expressions']
        ).remove($.view(this).parent.getIndex());
      });
  };

  rulesList.prototype.refresh = function(values) {
    $.observable(this.values).refresh(values);
  };

  $.fn.rulesList = function(options) {
    var value;
    var args = Array.prototype.slice.call(arguments, 1);
    this.each(function() {
      var $this = $(this),
          data = $this.data('location.rules');
      if (typeof options === 'string') {
        if (options != "refresh") {
          throw new Error("Unknown method: " + options);
        }
        value = data[options].apply(data, args);
      }
      if (!data) {
        $this.data('location.rules', (data = new rulesList(this, (typeof options === 'string' ? {} : options))));
      }
    });
    if (typeof value === 'undefined') {
      return this;
    } else {
      return value;
    }
  };
}(jQuery));

$(function() {
  $('[data-locations]').rulesList();

  var simpleui = $('#locations #middle #locsimple');
  var advancedui = $('#locations #middle #locadvanced');

  function updateFromSimple(score, node) {
    if (!score)
      return;
    var expr = [];
    if (node) {
      expr.push({ value: node, attribute: "#uname", operation: "eq", kind: "uname" });
    }
    var rules = [{ score: score, expressions: expr }];
    advancedui.find('[data-locations]').rulesList('refresh', rules);
  }

  simpleui.on('click', ".dropdown-menu a", function() {
    var value = $(this).data('value');
    simpleui.find('#simple-score').val(value).trigger('change');
  }).on('change', "#simple-score", function() {
    var value = $(this).val();
    var node = simpleui.find("#simple-node").val();
    updateFromSimple(value, node);
  }).on('change', "#simple-node", function() {
    var value = $(this).val();
    var score = simpleui.find('#simple-score').val();
    updateFromSimple(score, value);
  });

  $('[data-locations]').each(function() {
    var values = $(this).data('locations');
    var node_value = null;
    var score_value = null;
    if (values.length == 1 &&
        values[0].expressions &&
        values[0].expressions.length == 1) {
      var rule = values[0];
      var expr = rule.expressions[0];
      if (!("score" in rule) || rule.score == "") {
      } else if ("role" in rule && rule.role != "") {
      } else if (!expr.value || expr.attribute != "#uname" || expr.operation != "eq") {
      } else {
        score_value = rule.score;
        node_value = expr.value;
      }
    } else if (values.length == 1 &&
               ("expressions" in values[0]) &&
               values[0].expressions.length == 0) {
      if (values[0]["score"] == "INFINITY" &&
          values[0]["role"] == "" &&
          values[0]["operator"] == "and") {
        score_value = "INFINITY";
        node_value = '';
      }
    }
    if (score_value !== null && node_value !== null) {
      simpleui.find("#simple-score").val(score_value);
      if ($.grep(simpleui.find("#simple-node option"), function(opt) {
        return opt.value == node_value;
      }).length == 0) {
        simpleui.find("#simple-node").append('<option value="' + node_value + '">' + node_value + '</option>');
      }
      simpleui.find("#simple-node").val(node_value);
    }
    if (score_value === null || node_value === null || advancedui.find('[name="location[discovery]"]').val() != '') {
      $('[aria-controls="locadvanced"]').tab('show');
    }
  });
});
