// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  $('#primitives #middle table.primitives')
    .bootstrapTable({
      method: 'get',
      url: Routes.cib_primitives_path(
        $('body').data('cib'),
        { format: 'json' }
      ),
      striped: true,
      pagination: true,
      pageSize: 50,
      pageList: [10, 25, 50, 100, 200],
      sidePagination: 'client',
      smartDisplay: false,
      search: true,
      searchAlign: 'left',
      showColumns: true,
      showRefresh: true,
      minimumCountColumns: 0,
      sortName: 'id',
      sortOrder: 'asc',
      columns: [{
        field: 'id',
        title: __('Primitive ID'),
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

            try {
              answer = confirm(
                i18n.translate(
                  'Are you sure you wish to delete %s?'
                ).fetch(row.id)
              );
            } catch (e) {
              (console.error || console.log).call(console, e.stack || e);
            }

            if (answer) {
              $.ajax({
                dataType: 'json',
                method: 'POST',
                data: {
                  _method: 'delete'
                },
                url: Routes.cib_primitive_path(
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
            }
          }
        },
        formatter: function(value, row, index) {
          var operations = []

          operations.push([
            '<a href="',
                Routes.edit_cib_primitive_path(
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
                Routes.cib_primitive_path(
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
      $.each(longdesc, function(i, v) { if (v) ret.push('<p>', v, '</p>'); });
      return ret.join("");
    };

    if (agent != null) {
      $.ajax({
        dataType: "json",
        url: Routes.agent_path(),
        data: {id: agent, format: "json"},
        success: function(data) {
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
              if ("type" in v.content)
                type = v.content.type;
              if ("default" in v.content)
                defvalue = v.content["default"];
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

        },
        error: function(xhr, status, msg) {
          console.log('error', arguments);
          $.growl({
            message: __('Failed to fetch meta attributes')
          },{
            type: 'danger'
          });
        }
      });
    }
  };

  $('#primitives #middle form')
    .on('change', 'select#primitive_template', function(e) {
      var $form = $(e.delegateTarget);
      var $template = $form.find('#primitive_template');
      var $clazz = $form.find('#primitive_clazz');
      var $provider = $form.find('#primitive_provider');
      var $type = $form.find('#primitive_type');

      if ($template.val()) {
        var $option = $template.find('option:selected');
        $clazz.val($option.data('clazz')).attr('disabled', true);
        $provider.val($option.data('provider')).attr('disabled', true);
        $type.val($option.data('type')).attr('disabled', true);
      } else {
        $clazz.val('').removeAttr('disabled');
        $provider.val('');
        $type.val('');
      }
    })
    .on('change', 'select#primitive_clazz', function(e) {
      var $form = $(e.delegateTarget);
      var $clazz = $form.find('#primitive_clazz');
      var $provider = $form.find('#primitive_provider');
      var $type = $form.find('#primitive_type');

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
      $type.val('');
    })
    .on('change', 'select#primitive_provider', function(e) {
      var $form = $(e.delegateTarget);

      var $clazz = $form.find('#primitive_clazz');
      var $provider = $form.find('#primitive_provider');
      var $type = $form.find('#primitive_type');

      $type
        .find('[data-clazz][data-provider]')
        .show()
        .not('[data-clazz="' + $clazz.val() + '"][data-provider="' + $provider.val() + '"]')
        .hide()
        .end();

      $type.val('');
    })
    .on('change', 'select#primitive_template, select#primitive_clazz, select#primitive_provider, select#primitive_type', function(e) {
      var $form = $(e.delegateTarget);

      var $template = $form.find('#primitive_template');
      var $clazz = $form.find('#primitive_clazz');
      var $provider = $form.find('#primitive_provider');
      var $type = $form.find('#primitive_type');

      render_attrlists($template, $clazz, $provider, $type);
    })
    .find('#primitive_template, #primitive_clazz, #primitive_provider')
    .trigger('change');

  // triggering change does not work for editing...
  $('#primitives #middle form #primitive_clazz[readonly]').each(function() {
    var $form = $('#primitives #middle form');
    var $template = $form.find('#primitive_template');
    var $clazz = $form.find('#primitive_clazz');
    var $provider = $form.find('#primitive_provider');
    var $type = $form.find('#primitive_type');
    render_attrlists($template, $clazz, $provider, $type);
  });

});
