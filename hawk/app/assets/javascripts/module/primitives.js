// Copyright (c) 2009-2013 Tim Serong <tserong@suse.com>
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
            '" data-confirm="' + i18n.translate('Are you sure you wish to delete %s?').fetch(row.id) + '">',
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
    .on('change', '#primitive_template', function(e) {
      var $form = $(e.delegateTarget);
      var $target = $(e.currentTarget);

      if ($target.val()) {
        $option = $target.find('option:selected');

        $form
          .find('[name="primitive[clazz]"]')
            .val($option.data('clazz'))
            .attr('disabled', true)
          .end()
          .find('[name="primitive[provider]"]')
            .val($option.data('provider'))
            .attr('disabled', true)
          .end()
          .find('[name="primitive[type]"]')
            .val($option.data('type'))
            .attr('disabled', true)
          .end();
      } else {
        $form
          .find('[name="primitive[clazz]"]')
            .removeAttr('disabled')
          .end()
          .find('[name="primitive[provider]"]')
            .removeAttr('disabled')
          .end()
          .find('[name="primitive[type]"]')
            .removeAttr('disabled')
          .end();
      }
    })
    .on('change', '#primitive_clazz', function(e) {
      var $form = $(e.delegateTarget);

      var $clazz = $form.find('#primitive_clazz');
      var $provider = $form.find('#primitive_provider');
      var $type = $form.find('#primitive_type');

      $provider
        .find('[data-clazz]')
        .show()
        .not('[data-clazz="' + $clazz.val() + '"]')
        .hide();

      $type
        .find('[data-clazz][data-provider]')
        .show()
        .not('[data-clazz="' + $clazz.val() + '"][data-provider="' + $provider.val() + '"]')
        .hide()
        .end();

      $provider.val('');
      $type.val('');
    })
    .on('change', '#primitive_provider', function(e) {
      var $form = $(e.delegateTarget);

      var $clazz = $form.find('#primitive_clazz');
      var $provider = $form.find('#primitive_provider');
      var $type = $form.find('#primitive_type');

      $provider
        .find('[data-clazz]')
        .show()
        .not('[data-clazz="' + $clazz.val() + '"]')
        .hide();

      $type
        .find('[data-clazz][data-provider]')
        .show()
        .not('[data-clazz="' + $clazz.val() + '"][data-provider="' + $provider.val() + '"]')
        .hide()
        .end();

      $type.val('');
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
