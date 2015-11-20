// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  $('#constraints #middle table.constraints')
    .bootstrapTable({
      method: 'get',
      url: Routes.cib_constraints_path(
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
      showColumns: false,
      showRefresh: true,
      minimumCountColumns: 0,
      sortName: 'id',
      sortOrder: 'asc',
      columns: [{
        field: 'object_type',
        title: __('Type'),
        sortable: true,
        clickToSelect: true,
        class: 'col-sm-2',
        formatter: function(value, row, index) {
          switch(row.object_type) {
            case "location":
              return __("Location");
            case "colocation":
              return __("Colocation");
            case "order":
              return __("Order");
            case "ticket":
              return __("Ticket");
            default:
              return value;
          }
        }
      }, {
        field: 'id',
        title: __('Constraint'),
        sortable: true,
        switchable: false,
        clickToSelect: true
      }, {
        field: 'id',
        title: __('Operations'),
        sortable: false,
        clickToSelect: false,
        class: 'col-sm-2',
        events: {
          'click .delete': function (e, value, row, index) {
            var $self = $(this);
            $.hawkAsyncConfirm(i18n.translate('Are you sure you wish to delete %s?').fetch(row.id), function() {
              $.ajax({
                dataType: 'json',
                method: 'POST',
                data: {
                  _method: 'delete'
                },
                url: [
                  $self.attr('href'),
                  ".json"
                ].join(""),

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
            return false;
          }
        },
        formatter: function(value, row, index) {
          var operations = [];

          switch(row.object_type) {
            case "location":
              var editRoute = Routes.edit_cib_location_path(
                $('body').data('cib'),
                row.id
              );

              var deleteRoute = Routes.cib_location_path(
                $('body').data('cib'),
                row.id
              );

              break;
            case "colocation":
              var editRoute = Routes.edit_cib_colocation_path(
                $('body').data('cib'),
                row.id
              );

              var deleteRoute = Routes.cib_colocation_path(
                $('body').data('cib'),
                row.id
              );

              break;
            case "order":
              var editRoute = Routes.edit_cib_order_path(
                $('body').data('cib'),
                row.id
              );

              var deleteRoute = Routes.cib_order_path(
                $('body').data('cib'),
                row.id
              );

              break;
            case "ticket":
              var editRoute = Routes.edit_cib_ticket_path(
                $('body').data('cib'),
                row.id
              );

              var deleteRoute = Routes.cib_ticket_path(
                $('body').data('cib'),
                row.id
              );

              break;
            default:
              var editRoute = Routes.edit_cib_constraint_path(
                $('body').data('cib'),
                row.id
              );

              var deleteRoute = Routes.cib_constraint_path(
                $('body').data('cib'),
                row.id
              );

              break;
          }

          operations.push([
            '<a href="',
                editRoute,
              '" class="edit btn btn-default btn-xs" title="',
              __('Edit'),
            '">',
              '<i class="fa fa-pencil"></i>',
            '</a> '
          ].join(''));

          operations.push([
            '<a href="',
                deleteRoute,
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

  $('#constraints #middle form')
    .validate({
      rules: {
        'node[id]': {
          minlength: 1,
          required: true
        }
      }
    });
});
