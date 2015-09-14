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
        $clazz.removeAttr('disabled');
        if ($clazz.val() == "ocf") {
          $provider.removeAttr('disabled');
          $type.removeAttr('disabled');
        } else if ($clazz.val() == "") {
          $provider.val('').attr('disabled', true);
          $type.val('').attr('disabled', true);
        } else {
          $provider.val('').attr('disabled', true);
          $type.removeAttr('disabled');
        }
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

      $type.removeAttr('disabled');
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

      $.ajax({
        dataType: 'html',
        method: 'POST',
        data: {
          template: $template.val(),
          clazz: $clazz.val(),
          provider: $provider.val(),
          type: $type.val()
        },
        url: Routes.metas_cib_primitives_path(
          $('body').data('cib')
        ),
        success: function(data) {
          $('#metalist').html(data);
          $('#metalist [data-attrlist]').attrList();
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

      $.ajax({
        dataType: 'html',
        method: 'POST',
        data: {
          template: $template.val(),
          clazz: $clazz.val(),
          provider: $provider.val(),
          type: $type.val()
        },
        url: Routes.parameters_cib_primitives_path(
          $('body').data('cib')
        ),
        success: function(data) {
          $('#paramslist').html(data);
          $('#paramslist [data-attrlist]').attrList();
        },
        error: function(xhr, status, msg) {
          console.log('error', arguments);
          $.growl({
            message: __('Failed to fetch parameters')
          },{
            type: 'danger'
          });
        }
      });

      $.ajax({
        dataType: 'html',
        method: 'POST',
        data: {
          template: $template.val(),
          clazz: $clazz.val(),
          provider: $provider.val(),
          type: $type.val()
        },
        url: Routes.operations_cib_primitives_path(
          $('body').data('cib')
        ),
        success: function(data) {
          $('#opslist').html(data);
          $('#opslist [data-attrlist]').attrList();
        },
        error: function(xhr, status, msg) {
          console.log('error', arguments);
          $.growl({
            message: __('Failed to fetch operations')
          },{
            type: 'danger'
          });
        }
      });
    })
    .find('#primitive_template, #primitive_clazz, #primitive_provider')
      .trigger('change');

  // $('#primitives #middle form')
  //   .validate({
  //     rules: {
  //       'primitive[id]': {
  //         minlength: 1,
  //         required: true
  //       }
  //     }
  //   });
});
