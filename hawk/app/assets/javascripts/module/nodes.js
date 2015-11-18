// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  var rowStyleFn = function(row, index) {
    if (row.state == "online") {
      return { classes: ["success"] };
    } else if (row.state == "offline") {
      return { };
    } else if (row.state == "fence" || row.state == "unclean") {
      return { classes: ["danger"] };
    } else {
      return { classes: ["warning"] };
    }
  };

  $('#nodes #middle table.nodes, #states #middle table.nodes')
    .bootstrapTable({
      ajax: function(params) {
        var cib = $('body').data('content');
        params.success(cib.nodes, "success", {});
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
      sortName: 'name',
      sortOrder: 'asc',
      rowStyle: rowStyleFn,
      columns: [
        {
          field: 'state',
          title: __("Status"),
          sortable: true,
          clickToSelect: true,
          align: "center",
          halign: "center",
          class: 'detail',
          formatter: function(value, row, index) {
            var icon = ['fa', 'fa-lg'];
            var title = row.state;
            switch(row.state) {
            case 'online':
              icon.push('fa-circle', 'text-success');
              break;
            case 'offline':
              icon.push('fa-minus-circle', 'text-danger');
              break;
            case 'fence':
              icon.push('fa-plug', 'text-danger');
              break;
            case 'unclean':
              icon.push('fa-plug', 'text-danger');
              break;
            default:
              icon.push('fa-question-circle', 'text-warning');
              break;
            }
            var ret = ['<i class="', icon.join(' '), '" title="', title, '"></i>'];

            if (row.remote) {
              ret.push(' <i class="fa fa-cloud text-info" title="', __("Remote"), '"></i>');
            }

            return ret.join('');
          }
        }, {
          field: 'name',
          title: __('Name'),
          sortable: true,
          switchable: false,
          clickToSelect: true
        }, {
          field: 'maintenance',
          title: __('Maintenance'),
          align: 'right',
          halign: 'right',
          sortable: false,
          clickToSelect: true,
          class: 'col-sm-1',
          events: {
            'click .ready': function (e, value, row, index) {
              e.preventDefault();
              var $self = $(this);

              $.hawkAsyncConfirm(i18n.translate('This will bring node %s out of maintenance mode. Do you want to continue?').fetch(row.name), function() {
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
              });
            },
            'click .maintenance': function (e, value, row, index) {
              e.preventDefault();
              var $self = $(this);

              $.hawkAsyncConfirm(i18n.translate('This will put node %s in maintenance mode. All resources on this node will become unmanaged. Do you want to continue?').fetch(row.name), function() {
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
              });
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
          sortable: false,
          clickToSelect: true,
          class: 'col-sm-1',
          align: 'right',
          halign: 'right',
          events: {
            'click .online': function (e, value, row, index) {
              e.preventDefault();
              var $self = $(this);

              $.hawkAsyncConfirm(i18n.translate('This will bring node %s online if it is currently on standby. Do you want to continue?').fetch(row.name), function() {
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
              });
            },
            'click .standby': function (e, value, row, index) {
              e.preventDefault();
              var $self = $(this);

              $.hawkAsyncConfirm(i18n.translate('This will put node %s on standby. All resources will be stopped and/or moved to another node. Do you want to continue?').fetch(row.name), function() {
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
              });
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
          align: 'right',
          halign: 'right',
          class: 'col-sm-2',
          events: {
            'click .fence': function (e, value, row, index) {
              e.preventDefault();
              var $self = $(this);

              $.hawkAsyncConfirm(i18n.translate('This will attempt to immediately fence node %s. Do you want to continue?').fetch(row.name), function() {
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
              });
            }
          },
          formatter: function(value, row, index) {
            var operations = [];
            var dropdowns = [];

            var add_operation = function(dest, path, path_class, icon_class, text) {
              if (dest == "menu") {
                dropdowns.push([
                  '<li>',
                    '<a href="', path, '" class="', path_class, '">',
                      '<i class="fa fa-fw fa-', icon_class, '"></i> ',
                      text,
                    '</a>',
                  '</li>'
                ].join(''));
              } else if (dest == "button") {
                operations.push([
                  '<a href="', path, '" class="', path_class, ' btn btn-default btn-xs" title="', text, '">',
                    '<i class="fa fa-', icon_class, '"></i>',
                  '</a> '
                ].join(''));
              }
            };

            if (row.fence) {
              add_operation("menu", Routes.fence_cib_node_path($('body').data('cib'), row.id), 'fence', 'plug', __('Fence'));

              operations.push([
                '<div class="btn-group" role="group">',
                '<button class="btn btn-default btn-xs dropdown-toggle" type="button" data-toggle="dropdown" data-container="body" aria-haspopup="true" aria-expanded="true">',
                '<span class="caret"></span>',
                '</button>',
                '<ul class="dropdown-menu">',
                dropdowns.join(''),
                '</ul>',
                '</div>'
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

  $('#nodes #middle table.nodes, #states #middle table.nodes').on("click", ".dropdown-toggle", function(event){
    var button = $(this);
    var open = button.attr('aria-expanded');
    var dropdown = button.siblings('.dropdown-menu');
    if (open) {
      dropdown.css('top', button.offset().top - $(window).scrollTop() + button.outerHeight() + "px");
      dropdown.css('left', (button.offset().left + button.outerWidth() - dropdown.outerWidth()) + "px");
      dropdown.css('position', 'fixed');
    }
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
