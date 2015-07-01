// Copyright (c) 2009-2013 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  $('#colocations #middle table.colocations')
    .bootstrapTable({
      method: 'get',
      url: Routes.cib_colocations_path(
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
        title: __('Constraint ID'),
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
              url: Routes.cib_colocation_path(
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
                Routes.edit_cib_colocation_path(
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
                Routes.cib_colocation_path(
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

  // $('#colocations #middle form')
  //   .validate({
  //     rules: {
  //       'ticket[id]': {
  //         minlength: 1,
  //         required: true
  //       }
  //     }
  //   });
});
