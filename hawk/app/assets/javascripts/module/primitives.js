// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  // Some craziness to avoid duplicating this stuff for both
  // primitives and templates. The whole thing is looped over
  // twice, once for primitive and once for template
  var controller_types = {
    primitive: {
      table_selector: '#primitives #middle table.primitives, #configs #middle table.primitives',
      cib_primitives_path: Routes.cib_primitives_path,
      cib_primitive_path: Routes.cib_primitive_path,
      edit_cib_primitive_path: Routes.edit_cib_primitive_path,
      form_selector: '#primitives #middle form',
      template_selector: '#primitive_template',
      clazz_selector: '#primitive_clazz',
      provider_selector: '#primitive_provider',
      type_selector: '#primitive_type',
    },
    template: {
      table_selector: '#templates #middle table.primitives, #configs #middle table.templates',
      cib_primitives_path: Routes.cib_templates_path,
      cib_primitive_path: Routes.cib_template_path,
      edit_cib_primitive_path: Routes.edit_cib_template_path,
      form_selector: '#templates #middle form',
      template_selector: '#template_template',
      clazz_selector: '#template_clazz',
      provider_selector: '#template_provider',
      type_selector: '#template_type',
    }
  };

  $.each(controller_types, function(_, controller_type) {
    controller_type.sel_template = "select" + controller_type.template_selector;
    controller_type.sel_clazz = "select" + controller_type.clazz_selector;
    controller_type.sel_provider = "select" + controller_type.provider_selector;
    controller_type.sel_type = "select" + controller_type.type_selector;
    controller_type.selects = [controller_type.sel_template,
                               controller_type.sel_clazz,
                               controller_type.sel_provider,
                               controller_type.sel_type].join(", ");
    controller_type.sel_template_clazz_provider = [controller_type.template_selector,
                                                   controller_type.clazz_selector,
                                                   controller_type.provider_selector].join(", ");
    controller_type.sel_readonly = controller_type.form_selector + ' ' + controller_type.clazz_selector + '[readonly]';

    $(controller_type.table_selector)
      .bootstrapTable({
        method: 'get',
        url: controller_type.cib_primitives_path(
          $('body').data('cib'),
          { format: 'json' }
        ),
        striped: true,
        pagination: true,
        pageSize: 25,
        pageList: [10, 25, 50, 100, 200],
        sidePagination: 'client',
        smartDisplay: false,
        search: true,
        searchAlign: 'left',
        showColumns: false,
        showRefresh: true,
        minimumCountColumns: 0,
        sortName: 'id',
        sortOrder: 'asc',
        columns: [{
          field: 'id',
          title: __('Resource ID'),
          sortable: true,
          switchable: false,
          clickToSelect: true
        }, {
          field: 'operate',
          title: __('Operations'),
          sortable: false,
          clickToSelect: false,
          class: 'col-sm-2',
          events: {
            'click .delete': function (e, value, row, index) {
              e.preventDefault();
              var $self = $(this);
              var answer = null;

              $.hawkAsyncConfirm(i18n.translate('Are you sure you wish to delete %s?').fetch(row.id), function() {
                $.ajax({
                  dataType: 'json',
                  method: 'POST',
                  data: {
                    _method: 'delete'
                  },
                  url: controller_type.cib_primitive_path(
                    $('body').data('cib'),
                    row.id,
                    { format: 'json' }
                  ),

                  success: function(data) {
                    if (data.success) {
                      $.growl({
                        message: data.message
                      },{
                        type: 'success'
                      });

                      $self.parents('table').bootstrapTable('refresh')
                    } else {
                      if (data.error) {
                        $.growl({
                          message: data.error
                        },{
                          type: 'danger'
                        });
                      }
                    }
                  },
                  error: function(xhr, status, msg) {
                    $.growl({
                      message: xhr.responseJSON.error || msg
                    },{
                      type: 'danger'
                    });
                  }
                });
              });
            }
          },
          formatter: function(value, row, index) {
            var operations = []

            operations.push([
              '<a href="',
              controller_type.edit_cib_primitive_path(
                $('body').data('cib'),
                row.id
              ),
              '" class="edit btn btn-default btn-xs" title="',
              __('Edit'),
              '">',
              '<i class="fa fa-pencil"></i>',
              '</a> '
            ].join(''));

            operations.push([
              '<a href="',
              controller_type.cib_primitive_path(
                $('body').data('cib'),
                row.id
              ),
              '" class="delete btn btn-default btn-xs" title="',
              __('Delete'),
              '">',
              '<i class="fa fa-trash"></i>',
              '</a> '
            ].join(''));

            return [
              '<div class="btn-group" role="group">',
              operations.join(''),
              '</div>',
            ].join('');
          }
        }]
      });

    var enable_detail_for = function(agent) {
      // enable create/apply
      var form = $(controller_type.form_selector);
      form.find('#agent-info').removeClass('hidden').find('a').attr('href', Routes.cib_agent_path($('body').data('cib'), encodeURIComponent(agent)));
      form.find('#editform-loading').show();
      form.find(".submit").prop("disabled", false);
    };

    var disable_detail = function() {
      var form = $(controller_type.form_selector);
      form.find('#agent-info').addClass('hidden').find('a').attr('href', '#');
      form.find('#editform-loading').hide();
      form.find(".submit").prop("disabled", true);
      form.find('#paramslist, #oplist, #metalist, #utilizationlist').html('');
    };

    var render_attrlists = function($template, $clazz, $provider, $type) {
      var new_resource = $('form#new_primitive, form#new_template').length > 0;
      var agent = null;
      if ($template.length > 0 && $template.val() != "") {
        agent = "@" + $template.val();
      } else if ($clazz.val() != "" && $provider.val() != "" && $type.val() != "") {
        agent = [$clazz.val(), $provider.val(), $type.val()].join(":");
      } else if ($clazz.val() != "" && $type.val() != "") {
        agent = [$clazz.val(), $type.val()].join(":");
      }

      var format_longdesc = function(text) {
        var longdesc = $.map(text.split('\n\n'), function(v) { return $.trim(v); });
        var ret = [];
        $.each(longdesc, function(i, v) {
          if (v) {
            ret.push('<p>', v, '</p>');
          }
        });
        return ret.join("");
      };

      if (agent != null) {
        enable_detail_for(agent);
        $.ajax({
          dataType: "json",
          data: { format: "json" },
          url: Routes.cib_agent_path($('body').data('cib'), encodeURIComponent(agent)),
          success: function(data) {
            if (data == null || !("resource_agent" in data)) {
              data = { resource_agent: {
                shortdesc: agent,
                longdesc: "",
              } };
            }
            if (!("shortdesc" in data.resource_agent) || !data.resource_agent.shortdesc)
              data.resource_agent.shortdesc = agent;
            if (!("longdesc" in data.resource_agent) || !data.resource_agent.longdesc)
              data.resource_agent.longdesc = "";
            // Update the sidebar with agent info
            var helptext = ['<h3>', data.resource_agent.shortdesc, '</h3>'];
            helptext.push(format_longdesc(data.resource_agent.longdesc));
            $('.row.agentinfo').html(helptext.join(""));

            // TODO: update the sidebar with attribute help info
            $("#helpentries").html('');

            var lookup = function(root, lstname, elemname) {
              if (lstname in root) {
                if ($.type(root[lstname]) == "object") {
                  if (elemname in root[lstname]) {
                    if ($.type(root[lstname][elemname]) == "object") {
                      return [root[lstname][elemname]];
                    } else {
                      return root[lstname][elemname];
                    }
                  }
                }
              }
              return [];
            };

            // display attrlists
            // attrlist: {'name': 'value'}
            // mapping: {'name': {'type', 'default', 'longdesc', 'values'}}
            var pal = {};
            var pam = {};
            $.each(lookup(data.resource_agent, "parameters", "parameter"), function(i, v) {
              var name = v.name;
              var longdesc = "";
              if ($.trim(v.longdesc)) {
                longdesc = v.longdesc;
              } else if ($.trim(v.shortdesc)) {
                longdesc = v.shortdesc;
              }
              var type = "string";
              var defvalue = "";
              if ("content" in v && v.content) {
                if ("type" in v.content) {
                  type = v.content.type;
                }
                if ("default" in v.content) {
                  defvalue = v.content["default"];
                }
              }
              if (v.required == "1") {
                pal[v.name] = defvalue;
              }
              pam[v.name] = {
                type: type,
                default: defvalue,
                longdesc: v.shortdesc + ": " + v.longdesc
              };
              $("#helpentries").append($("#tmpl-helpentry").render({
                name: name,
                longdesc: longdesc,
                default: defvalue
              }));
            });

            $('form #paramslist').html($("#jstmpl-paramslist").render());
            var paramslist = $('form #paramslist fieldset');
            if (new_resource) {
              paramslist.data('attrlist', pal);
            }
            paramslist.data('attrlist-mapping', pam);
            paramslist.attrList();

            // meta attributes are never mandated by the agent anyway
            $('form #metalist').html($("#jstmpl-metalist").render());
            var metalist = $('form #metalist fieldset');
            if (new_resource) {
              metalist.data('attrlist', {'target-role': 'Stopped'});
            }
            metalist.attrList();
            $("#helpentries").append($("#tmpl-metahelp").render());

            // utilization
            $('form #utilizationlist').html($("#jstmpl-utilizationlist").render());
            var utilizationlist = $('form #utilizationlist fieldset');
            utilizationlist.attrList();

            $('form #oplist').html($("#jstmpl-oplist").render());
            var oplist = $('form #oplist fieldset');
            oplist.data('oplist-actions', lookup(data.resource_agent, "actions", "action"));
            oplist.opList({create: new_resource});

            // hide help texts
            $('[data-help-target]').each(function() {
              $($(this).data('help-target')).hide();
            });


            // enable toggleables
            $('form').toggleify();

            $(controller_type.form_selector).find('#editform-loading').hide();
          },
          error: function(xhr, status, msg) {
            $(controller_type.form_selector).find('#editform-loading').hide();
            $.growl({
              message: __('Failed to fetch meta attributes')
            },{
              type: 'danger'
            });
          }
        });
      } else {
        disable_detail();
      }
    };

    $(controller_type.form_selector)
      .on('change', controller_type.sel_template, function(e) {
        var $form = $(e.delegateTarget);
        var $template = $form.find(controller_type.template_selector);
        var $clazz = $form.find(controller_type.clazz_selector);
        var $provider = $form.find(controller_type.provider_selector);
        var $type = $form.find(controller_type.type_selector);

        if ($template.val()) {
          var $option = $template.find('option:selected');
          $clazz.val($option.data('clazz')).attr('disabled', true);
          $provider.val($option.data('provider')).attr('disabled', true);
          $type.val($option.data('type')).attr('disabled', true);
        } else if ($clazz.val() && $type.val()) {
          $clazz.removeAttr('disabled');
          if ($provider.val()) {
            $provider.removeAttr('disabled');
          }
          $type.removeAttr('disabled');
        } else {
          $clazz.val('').removeAttr('disabled');
          $provider.val('');
          $type.val('');
        }
      })
      .on('change', controller_type.sel_clazz, function(e) {
        var $form = $(e.delegateTarget);
        var $clazz = $form.find(controller_type.clazz_selector);
        var $provider = $form.find(controller_type.provider_selector);
        var $type = $form.find(controller_type.type_selector);

        if ($clazz.attr('disabled') == 'disabled') {
          // changing while disabled: we're a template
          return;
        }

        if ($clazz.val() == "ocf") {
          $provider
            .find('[data-clazz]')
            .show()
            .not('[data-clazz="' + $clazz.val() + '"]')
            .hide();
          $provider.removeAttr('disabled');
          $provider.val('heartbeat');
        } else {
          $provider.val('').attr('disabled', true);
        }

        if ($clazz.val() == "") {
          $type.val('').attr('disabled', true);
        } else {
          $type.removeAttr('disabled');
        }
        $type
          .find('[data-clazz][data-provider]')
          .show()
          .not('[data-clazz="' + $clazz.val() + '"][data-provider="' + $provider.val() + '"]')
          .hide()
          .end();

        if ($type.find('[data-clazz="' + $clazz.val() + '"][data-provider="' + $provider.val() + '"][value="' + $type.val() + '"]').length == 0) {
          $type.val('');
        }
      })
      .on('change', controller_type.sel_provider, function(e) {
        var $form = $(e.delegateTarget);

        var $clazz = $form.find(controller_type.clazz_selector);
        var $provider = $form.find(controller_type.provider_selector);
        var $type = $form.find(controller_type.type_selector);

        if ($provider.attr('disabled') == 'disabled') {
          // changing while disabled: we're a template
          return;
        }

        $type
          .find('[data-clazz][data-provider]')
          .show()
          .not('[data-clazz="' + $clazz.val() + '"][data-provider="' + $provider.val() + '"]')
          .hide()
          .end();

        if ($type.find('[data-clazz="' + $clazz.val() + '"][data-provider="' + $provider.val() + '"][value="' + $type.val() + '"]').length == 0) {
          $type.val('');
        }
      })
      .on('change', controller_type.selects, function(e) {
        var $form = $(e.delegateTarget);

        var $template = $form.find(controller_type.template_selector);
        var $clazz = $form.find(controller_type.clazz_selector);
        var $provider = $form.find(controller_type.provider_selector);
        var $type = $form.find(controller_type.type_selector);

        render_attrlists($template, $clazz, $provider, $type);
      })
      .find(controller_type.sel_template_clazz_provider)
      .trigger('change');

    // triggering change does not work for editing...
    $(controller_type.sel_readonly).each(function() {
      var $form = $(controller_type.form_selector);
      var $template = $form.find(controller_type.template_selector);
      var $clazz = $form.find(controller_type.clazz_selector);
      var $provider = $form.find(controller_type.provider_selector);
      var $type = $form.find(controller_type.type_selector);
      render_attrlists($template, $clazz, $provider, $type);
    });
  });

});
