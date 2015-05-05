//======================================================================
//                        HA Web Konsole (Hawk)
// --------------------------------------------------------------------
//            A web-based GUI for managing and monitoring the
//          Pacemaker High-Availability cluster resource manager
//
// Copyright (c) 2009-2013 SUSE LLC, All Rights Reserved.
//
// Author: Tim Serong <tserong@suse.com>
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of version 2 of the GNU General Public License as
// published by the Free Software Foundation.
//
// This program is distributed in the hope that it would be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//
// Further, this software is distributed without any warranty that it is
// free of the rightful claim of any third person regarding infringement
// or the like.  Any license provided herein, whether implied or
// otherwise, applies only to this software file.  Patent licenses, if
// any, provided herein do not apply to combinations of this program with
// other software, or any other product whatsoever.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write the Free Software Foundation,
// Inc., 59 Temple Place - Suite 330, Boston MA 02111-1307, USA.
//
//======================================================================

$(function() {
  $('#nodes #middle table.nodes, #dashboards #middle table.nodes')
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
                '<i class="fa fa-play" title="',
                  row.state,
                '"></i>'
              ].join('');
              break;

            case 'offline':
              return [
                '<i class="fa fa-stop" title="',
                  row.state,
                '"></i>'
              ].join('');
              break;

            case 'fence':
              return [
                '<i class="fa fa-exclamation-triangle" title="',
                  row.state,
                '"></i>'
              ].join('');
              break;

            default:
              return [
                '<i class="fa fa-exclamation-triangle" title="',
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
        formatter: function(value, row, index) {
          if (row.maintenance) {
            return [
              '<i class="fa fa-toggle-on text-danger" title="',
                __('Yes'),
              '"></i>'
            ].join('');
          } else {
            return [
              '<i class="fa fa-toggle-off text-success" title="',
                __('No'),
              '"></i>'
            ].join('');
          }
        }
      }, {
        field: 'standby',
        title: __('Standby'),
        sortable: true,
        clickToSelect: true,
        class: 'col-sm-1',
        formatter: function(value, row, index) {
          if (row.standby) {
            return [
              '<i class="fa fa-toggle-on text-danger" title="',
                __('Yes'),
              '"></i>'
            ].join('');
          } else {
            return [
              '<i class="fa fa-toggle-off text-success" title="',
                __('No'),
              '"></i>'
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
          'click .online': function (e, value, row, index) {
            e.preventDefault();
            var $self = $(this);

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
          },
          'click .standby': function (e, value, row, index) {
            e.preventDefault();
            var $self = $(this);

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
          },
          'click .ready': function (e, value, row, index) {
            e.preventDefault();
            var $self = $(this);

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
          },
          'click .maintenance': function (e, value, row, index) {
            e.preventDefault();
            var $self = $(this);

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
          },
          'click .fence': function (e, value, row, index) {
            e.preventDefault();
            var $self = $(this);

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
        },
        formatter: function(value, row, index) {
          var operations = []

          if (!row.online) {
            operations.push([
              '<a href="',
                Routes.online_cib_node_path(
                  $('body').data('cib'),
                  row.id
                ),
              '" class="online btn btn-default btn-xs" title="',
                __('Online'),
              '" data-confirm="' + i18n.translate('This will bring node %s online if it is currently on standby. Do you want to continue?').fetch(row.name) + '">',
                '<i class="fa fa-play"></i>',
              '</a> '
            ].join(''));
          }

          if (!row.standby) {
            operations.push([
              '<a href="',
                Routes.standby_cib_node_path(
                  $('body').data('cib'),
                  row.id
                ),
              '" class="standby btn btn-default btn-xs" title="',
                __('Standby'),
              '" data-confirm="' + i18n.translate('This will put node %s on standby. All resources will be stopped and/or moved to another node. Do you want to continue?').fetch(row.name) + '">',
                '<i class="fa fa-pause"></i>',
              '</a> '
            ].join(''));
          }

          if (!row.ready) {
            operations.push([
              '<a href="',
                  Routes.ready_cib_node_path(
                    $('body').data('cib'),
                    row.id
                  ),
                '" class="ready btn btn-default btn-xs" title="',
                __('Ready'),
              '" data-confirm="' + i18n.translate('This will bring node %s out of maintenance mode. Do you want to continue?').fetch(row.name) + '">',
                '<i class="fa fa-check"></i>',
              '</a> '
            ].join(''));
          }

          if (!row.maintenance) {
            operations.push([
              '<a href="',
                Routes.maintenance_cib_node_path(
                  $('body').data('cib'),
                  row.id
                ),
              '" class="maintenance btn btn-default btn-xs" title="',
                __('Maintenance'),
              '" data-confirm="' + i18n.translate('This will put node %s in maintenance mode. All resources on this node will become unmanaged. Do you want to continue?').fetch(row.name) + '">',
                '<i class="fa fa-wrench"></i>',
              '</a> '
            ].join(''));
          }

          if (!row.fence) {
            operations.push([
              '<a href="',
                  Routes.fence_cib_node_path(
                    $('body').data('cib'),
                    row.id
                  ),
                '" class="fence btn btn-default btn-xs" title="',
                __('Fence'),
              '" data-confirm="' + i18n.translate('This will attempt to immediately fence node %s. Do you want to continue?').fetch(row.name) + '">',
                '<i class="fa fa-arrow-circle-right"></i>',
              '</a> '
            ].join(''));
          }

          if ($('body').data('god') === 'true') {
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
          }

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
