// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  var constraintResources = function(row) {
    var flattenResourceList = null;
    flattenResourceList = function(obj) {
      var t = $.type(obj);
      var ret = [];
      if (t === "string") {
        ret.push(obj);
      } else if (t === "array") {
        $.each(obj, function(i, o) {
          ret = ret.concat(flattenResourceList(o));
        });
      } else if (t === "object") {
        if ("resources" in obj) {
          ret = ret.concat(flattenResourceList(obj.resources));
        }
        if ("resource" in row) {
          ret = ret.concat(flattenResourceList(obj.resource));
        }
      }
      return ret;
    };
    var lst = flattenResourceList(row);
    if (lst.length > 8) {
      lst = lst.slice(0, 8);
      lst.push("...");
    }
    return lst.join(", ");
  };

  $('#constraints #middle table.constraints, #configs #middle table.constraints')
    .bootstrapTable({
      method: 'get',
      url: Routes.cib_constraints_path(
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
      columns: [ {
        field: 'id',
        title: __('Name'),
        class: 'col-sm-4',
        sortable: true,
        switchable: false,
        clickToSelect: true
      }, {
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
        title: __('Resources'),
        sortable: false,
        switchable: false,
        clickToSelect: false,
        formatter: function(value, row, index) {
          return constraintResources(row);
        }
      }, {
        field: 'id',
        title: __('Operations'),
        sortable: false,
        clickToSelect: false,
        class: 'col-sm-2',
        events: {
          'click .delete': function (e, value, row, index) {
            e.preventDefault();
            var $self = $(this);
            $.hawkAsyncConfirm(i18n.translate('Are you sure you wish to delete %s?').fetch(row.id), function() {
              $.ajax({
                dataType: 'json',
                method: 'POST',
                data: {
                  _method: 'delete'
                },
                url: [
                  $self.attr('href')
                ],

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
            Routes.rename_cib_constraint_path($('body').data('cib'), row.id),
            '" class="rename btn btn-default btn-xs" title="',
            __('Rename'),
            '" data-toggle="modal" data-target="#modal">',
            '<i class="fa fa-font"></i>',
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
