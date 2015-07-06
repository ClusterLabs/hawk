// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  $('#nodes #middle table.nodes, #states #middle table.nodes')
    .bootstrapTable({
      method: 'get',
      url: Routes.cib_nodes_path(
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
      sortName: 'name',
      sortOrder: 'asc',
      columns: [{
        field: 'state',
        title: __('Status'),
        sortable: true,
        clickToSelect: true,
        class: 'col-sm-1',
        formatter: function(value, row, index) {
          switch(row.state) {
            case 'online':
              return [
                '<i class="fa fa-play text-success" title="',
                  row.state,
                '"></i>'
              ].join('');
              break;

            case 'offline':
              return [
                '<i class="fa fa-stop text-info" title="',
                  row.state,
                '"></i>'
              ].join('');
              break;

            case 'fence':
              return [
                '<i class="fa fa-exclamation-triangle text-danger" title="',
                  row.state,
                '"></i>'
              ].join('');
              break;

            default:
              return [
                '<i class="fa fa-exclamation-triangle text-warning" title="',
                  row.state,
                '"></i>'
              ].join('');
              break;
          }
        }
      }, {
        field: 'name',
        title: __('Node'),
        sortable: true,
        switchable: false,
        clickToSelect: true
      }, {
        field: 'maintenance',
        title: __('Maintenance'),
        sortable: true,
        clickToSelect: true,
        class: 'col-sm-1',
        events: {
          'click .ready': function (e, value, row, index) {
            e.preventDefault();
            var $self = $(this);

            try {
              answer = confirm(
                i18n.translate(
                  'This will bring node %s out of maintenance mode. Do you want to continue?'
                ).fetch(row.name)
              );
            } catch (e) {
              (console.error || console.log).call(console, e.stack || e);
            }

            if (answer) {
              $.ajax({
                dataType: 'json',
                method: 'GET',
                url: Routes.ready_cib_node_path(
                  $('body').data('cib'),
                  row.id,
                  { format: 'json' }
                ),

                success: function(data) {
                  if (data.success) {
                    $.growl({
                      message: data.message
                    }, {
                      type: 'success'
                    });

                    $self.parents('table').bootstrapTable('refresh')
                  } else {
                    if (data.error) {
                      $.growl({
                        message: data.error
                      }, {
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
          'click .maintenance': function (e, value, row, index) {
            e.preventDefault();
            var $self = $(this);

            try {
              answer = confirm(
                i18n.translate(
                  'This will put node %s in maintenance mode. All resources on this node will become unmanaged. Do you want to continue?'
                ).fetch(row.name)
              );
            } catch (e) {
              (console.error || console.log).call(console, e.stack || e);
            }

            if (answer) {
              $.ajax({
                dataType: 'json',
                method: 'GET',
                url: Routes.maintenance_cib_node_path(
                  $('body').data('cib'),
                  row.id,
                  { format: 'json' }
                ),

                success: function(data) {
                  if (data.success) {
                    $.growl({
                      message: data.message
                    }, {
                      type: 'success'
                    });

                    $self.parents('table').bootstrapTable('refresh')
                  } else {
                    if (data.error) {
                      $.growl({
                        message: data.error
                      }, {
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
          if (row.maintenance) {
            return [
              '<a href="',
                  Routes.ready_cib_node_path(
                    $('body').data('cib'),
                    row.id
                  ),
                '" class="ready btn btn-default btn-xs" title="',
                __('Switch to ready'),
              '">',
                '<i class="fa fa-toggle-on text-danger"></i>',
              '</a>'
            ].join('');
          } else {
            return [
              '<a href="',
                Routes.maintenance_cib_node_path(
                  $('body').data('cib'),
                  row.id
                ),
              '" class="maintenance btn btn-default btn-xs" title="',
                __('Switch to maintenance'),
              '">',
                '<i class="fa fa-toggle-off text-success"></i>',
              '</a>'
            ].join('');
          }
        }
      }, {
        field: 'standby',
        title: __('Standby'),
        sortable: true,
        clickToSelect: true,
        class: 'col-sm-1',
        events: {
          'click .online': function (e, value, row, index) {
            e.preventDefault();
            var $self = $(this);

            try {
              answer = confirm(
                i18n.translate(
                  'This will bring node %s online if it is currently on standby. Do you want to continue?'
                ).fetch(row.name)
              );
            } catch (e) {
              (console.error || console.log).call(console, e.stack || e);
            }

            if (answer) {
              $.ajax({
                dataType: 'json',
                method: 'GET',
                url: Routes.online_cib_node_path(
                  $('body').data('cib'),
                  row.id,
                  { format: 'json' }
                ),

                success: function(data) {
                  if (data.success) {
                    $.growl({
                      message: data.message
                    }, {
                      type: 'success'
                    });

                    $self.parents('table').bootstrapTable('refresh')
                  } else {
                    if (data.error) {
                      $.growl({
                        message: data.error
                      }, {
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
          'click .standby': function (e, value, row, index) {
            e.preventDefault();
            var $self = $(this);

            try {
              answer = confirm(
                i18n.translate(
                  'This will put node %s on standby. All resources will be stopped and/or moved to another node. Do you want to continue?'
                ).fetch(row.name)
              );
            } catch (e) {
              (console.error || console.log).call(console, e.stack || e);
            }

            if (answer) {
              $.ajax({
                dataType: 'json',
                method: 'GET',
                url: Routes.standby_cib_node_path(
                  $('body').data('cib'),
                  row.id,
                  { format: 'json' }
                ),

                success: function(data) {
                  if (data.success) {
                    $.growl({
                      message: data.message
                    }, {
                      type: 'success'
                    });

                    $self.parents('table').bootstrapTable('refresh')
                  } else {
                    if (data.error) {
                      $.growl({
                        message: data.error
                      }, {
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
          if (row.standby) {
            return [
              '<a href="',
                Routes.online_cib_node_path(
                  $('body').data('cib'),
                  row.id
                ),
              '" class="online btn btn-default btn-xs" title="',
                __('Switch to online'),
              '">',
                '<i class="fa fa-toggle-on text-danger"></i>',
              '</a>'
            ].join('');
          } else {
            return [
              '<a href="',
                Routes.standby_cib_node_path(
                  $('body').data('cib'),
                  row.id
                ),
              '" class="standby btn btn-default btn-xs" title="',
                __('Switch to standby'),
              '">',
                '<i class="fa fa-toggle-off text-success"></i>',
              '</a>'
            ].join('');
          }
        }
      }, {
        field: 'operate',
        title: __('Operations'),
        sortable: false,
        clickToSelect: false,
        class: 'col-sm-2',
        events: {
          'click .fence': function (e, value, row, index) {
            e.preventDefault();
            var $self = $(this);

            try {
              answer = confirm(
                i18n.translate(
                  'This will attempt to immediately fence node %s. Do you want to continue?'
                ).fetch(row.name)
              );
            } catch (e) {
              (console.error || console.log).call(console, e.stack || e);
            }

            if (answer) {
              $.ajax({
                dataType: 'json',
                method: 'GET',
                url: Routes.fence_cib_node_path(
                  $('body').data('cib'),
                  row.id,
                  { format: 'json' }
                ),

                success: function(data) {
                  if (data.success) {
                    $.growl({
                      message: data.message
                    }, {
                      type: 'success'
                    });

                    $self.parents('table').bootstrapTable('refresh')
                  } else {
                    if (data.error) {
                      $.growl({
                        message: data.error
                      }, {
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

          if (!row.fence) {
            operations.push([
              '<a href="',
                  Routes.fence_cib_node_path(
                    $('body').data('cib'),
                    row.id
                  ),
                '" class="fence btn btn-default btn-xs" title="',
                __('Fence'),
              '">',
                '<i class="fa fa-arrow-circle-right"></i>',
              '</a> '
            ].join(''));
          }

          operations.push([
            '<a href="',
                Routes.events_cib_node_path(
                  $('body').data('cib'),
                  row.id
                ),
              '" class="events btn btn-default btn-xs" title="',
              __('Events'),
            '" data-toggle="modal" data-target="#modal">',
              '<i class="fa fa-files-o"></i>',
            '</a>'
          ].join(''));

          operations.push([
            '<a href="',
                Routes.cib_node_path(
                  $('body').data('cib'),
                  row.id
                ),
              '" class="details btn btn-default btn-xs" title="',
              __('Details'),
            '" data-toggle="modal" data-target="#modal">',
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

  $('#nodes #middle form')
    .validate({
      rules: {
        'node[id]': {
          minlength: 1,
          required: true
        }
      }
    });
});
