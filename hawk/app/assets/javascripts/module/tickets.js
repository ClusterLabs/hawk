// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  $('#tickets #middle table.tickets')
    .bootstrapTable({
      ajax: function(params) {
        var cib = $('body').data('content');
        params.success($.map(cib.tickets, function(t) {
          return t;
        }, "success", {}));
        params.complete({}, "success");
      },
      striped: true,
      pagination: true,
      pageSize: 50,
      pageList: [10, 25, 50, 100, 200],
      sidePagination: 'client',
      smartDisplay: false,
      search: true,
      searchAlign: 'left',
      showColumns: false,
      showRefresh: false,
      minimumCountColumns: 0,
      sortName: 'id',
      sortOrder: 'asc',
      columns: [{
        field: 'id',
        title: __('ID'),
        sortable: true,
        switchable: false,
        clickToSelect: true
      }, {
        field: 'ticket',
        title: __('Ticket'),
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
            e.preventDefault();
            var $self = $(this);

            if (row.id == null) {
              return false;
            }

            $.hawkAsyncConfirm(i18n.translate('Are you sure you wish to delete %s?').fetch(row.id), function() {
              $.ajax({
                dataType: 'json',
                method: 'POST',
                data: {
                  _method: 'delete'
                },
                url: Routes.cib_ticket_path(
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
            return false;
          }
        },
        formatter: function(value, row, index) {

          if (row.id == null) {
            return "";
          }

          var operations = []

          operations.push([
            '<a href="',
                Routes.edit_cib_ticket_path($('body').data('cib'), row.id),
              '" class="edit btn btn-default btn-xs" title="',
              __('Edit'),
            '">',
              '<i class="fa fa-pencil"></i>',
            '</a> '
          ].join(''));

          operations.push([
            '<a href="',
                Routes.cib_ticket_path($('body').data('cib'), row.id),
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

  $('#states #middle table.tickets')
    .bootstrapTable({
      ajax: function(params) {
        var cib = $('body').data('content');
        params.success($.map(cib.tickets, function(t) {
          return t;
        }, "success", {}));
        params.complete({}, "success");
      },
      pagination: false,
      pageSize: 50,
      pageList: [10, 25, 50, 100, 200],
      sidePagination: 'client',
      smartDisplay: false,
      search: true,
      searchAlign: 'left',
      showColumns: false,
      showRefresh: false,
      minimumCountColumns: 0,
      rowStyle: function(row, index) {
        if (row.state == "granted") {
          return { classes: ["success"] };
        } else if (row.state == "revoked") {
          return {};
        } else {
          return { classes: ["warning"] };
        }
      },
      sortName: 'ticket',
      sortOrder: 'asc',
      columns: [{
        field: 'state',
        title: __('Status'),
        sortable: true,
        clickToSelect: true,
        class: 'col-sm-1',
        formatter: function(value, row, index) {
          if (row.granted) {
            return [
              '<i class="fa fa-check-circle fa-lg text-success" title="',
              __("Granted"),
              '"></i>'
            ].join('');
          } else {
            return [
              '<i class="fa fa-ban fa-lg text-danger" title="',
              __("Revoked"),
              '"></i>'
            ].join('');
          }
        }
      }, {
        field: 'ticket',
        title: __('Ticket'),
        sortable: true,
        switchable: false,
        clickToSelect: true
      }, {
        field: 'id',
        title: __('Constraint ID'),
        sortable: true,
        switchable: false,
        clickToSelect: true
      }, {
        field: 'granted',
        title: __('Granted'),
        sortable: false,
        clickToSelect: true,
        class: 'col-sm-1',
        events: {
          'click .grant': function (e, value, row, index) {
            e.preventDefault();
            var $self = $(this);

            if (row.id == null) {
              return false;
            }

            $.hawkAsyncConfirm(i18n.translate('This will request the ticket %s be granted to the present site. Do you want to continue?').fetch(row.ticket), function() {
              $.ajax({
                dataType: 'json',
                method: 'GET',
                url: Routes.grant_cib_ticket_path(
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
            return false;
          },
          'click .revoke': function (e, value, row, index) {
            e.preventDefault();
            var $self = $(this);

            if (row.id == null) {
              return false;
            }

            $.hawkAsyncConfirm(i18n.translate('This will request the ticket %s be revoked. Do you want to continue?').fetch(row.ticket), function() {
              $.ajax({
                dataType: 'json',
                method: 'GET',
                url: Routes.revoke_cib_ticket_path(
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
            return false;
          }
        },
        formatter: function(value, row, index) {
          if (row.id == null) {
            if (!row.granted) {
              return '<a class="btn btn-default btn-xs disabled" disabled><i class="fa fa-toggle-off"></i><a>';
            } else {
              return '<a class="btn btn-default btn-xs disabled" disabled><i class="fa fa-toggle-on text-success"></i><a>';
            }
          }

          if (!row.granted) {
            return [
              '<a href="',
                Routes.grant_cib_ticket_path($('body').data('cib'), row.id),
              '" class="grant btn btn-default btn-xs" title="',
                __('Grant'),
              '">',
                '<i class="fa fa-toggle-off"></i>',
              '</a>'
            ].join('');
          } else {
            return [
              '<a href="',
                Routes.revoke_cib_ticket_path($('body').data('cib'), row.id),
              '" class="revoke btn btn-default btn-xs" title="',
                __('Revoke'),
              '">',
                '<i class="fa fa-toggle-on text-success"></i>',
              '</a>'
            ].join('');
          }
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

            if (row.id == null) {
              return false;
            }

            $.hawkAsyncConfirm(i18n.translate('Are you sure you wish to delete %s?').fetch(row.id), function() {
              $.ajax({
                dataType: 'json',
                method: 'POST',
                data: {
                  _method: 'delete'
                },
                url: Routes.cib_ticket_path(
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
            return false;
          }
        },
        formatter: function(value, row, index) {
          if (row.id == null) {
            return "";
          }

          var operations = [];

          operations.push([
            '<a href="',
                Routes.edit_cib_ticket_path($('body').data('cib'), row.id),
              '" class="edit btn btn-default btn-xs" title="',
              __('Edit'),
            '">',
              '<i class="fa fa-pencil"></i>',
            '</a> '
          ].join(''));

          operations.push([
            '<a href="',
            Routes.cib_ticket_path($('body').data('cib'), row.id),
            '" class="details btn btn-default btn-xs" title="',
            __('Details'),
            '" data-toggle="modal" data-target="#modal-lg">',
            '<i class="fa fa-search"></i>',
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

  // $('#tickets #middle form')
  //   .validate({
  //     rules: {
  //       'ticket[id]': {
  //         minlength: 1,
  //         required: true
  //       }
  //     }
  //   });
});
