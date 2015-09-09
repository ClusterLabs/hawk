// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  $('#templates #middle table.templates')
    .bootstrapTable({
      method: 'get',
      url: Routes.cib_templates_path(
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
        title: __('Template ID'),
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
                url: Routes.cib_template_path(
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
                Routes.edit_cib_template_path(
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
                Routes.cib_template_path(
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

  $('#templates #middle form')
    .on('change', 'select#template_clazz', function(e) {
      var $form = $(e.delegateTarget);
      var $clazz = $form.find('#template_clazz');
      var $provider = $form.find('#template_provider');
      var $type = $form.find('#template_type');

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
    .on('change', 'select#template_provider', function(e) {
      var $form = $(e.delegateTarget);

      var $clazz = $form.find('#template_clazz');
      var $provider = $form.find('#template_provider');
      var $type = $form.find('#template_type');

      $type
        .find('[data-clazz][data-provider]')
        .show()
        .not('[data-clazz="' + $clazz.val() + '"][data-provider="' + $provider.val() + '"]')
        .hide()
        .end();

      $type.val('');
    })
    .on('change', 'select#template_clazz, select#template_provider, select#template_type', function(e) {
      var $form = $(e.delegateTarget);

      var $clazz = $form.find('#template_clazz');
      var $provider = $form.find('#template_provider');
      var $type = $form.find('#template_type');

      $.ajax({
        dataType: 'html',
        method: 'POST',
        data: {
          clazz: $clazz.val(),
          provider: $provider.val(),
          type: $type.val()
        },
        url: Routes.metas_cib_templates_path(
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
          clazz: $clazz.val(),
          provider: $provider.val(),
          type: $type.val()
        },
        url: Routes.parameters_cib_templates_path(
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
          clazz: $clazz.val(),
          provider: $provider.val(),
          type: $type.val()
        },
        url: Routes.operations_cib_templates_path(
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
    .find('select#template_clazz, select#template_provider')
      .trigger('change');

  // $('#templates #middle form')
  //   .validate({
  //     rules: {
  //       'template[id]': {
  //         minlength: 1,
  //         required: true
  //       }
  //     }
  //   });
});
