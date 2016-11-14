// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  var rowStyleFn = function(row, index) {
    if (row.maintenance == true) {
      return { classes: ["info"] };
    } else if (row.state == "online") {
      return { classes: ["success"] };
    } else if (row.state == "offline") {
      return { };
    } else if (row.state == "fence" || row.state == "unclean") {
      return { classes: ["danger"] };
    } else {
      return { classes: ["warning"] };
    }
  };

  $('#cib #middle table.nodes')
    .bootstrapTable({
      ajax: function(params) {
        var cib = $('body').data('content');
        params.success(cib.nodes, "success", {});
        params.complete({}, "success");
      },
      classes: "table table-hover table-no-bordered",
      pagination: false,
      pageSize: 10,
      pageList: [10, 25, 50, 100, 200],
      sidePagination: 'client',
      smartDisplay: false,
      search: false,
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
          sortable: false,
          clickToSelect: false,
          align: "center",
          halign: "center",
          class: 'col-sm-1',
          formatter: function(value, row, index) {
            var cib = $('body').data('content');
            var icon = ['fa', 'fa-lg'];
            var title = row.state;
            switch(row.state) {
            case 'online':
              if (cib.meta.dc == row.name) {
                icon.push('fa-home', 'text-success');
                title += " (DC)";
              } else {
                icon.push('fa-circle', 'text-success');
              }
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
              ret.push(' <i class="fa fa-cloud fa-status-small text-info" title="', __("Remote"), '"></i>');
            }

            if (row.fence_history) {
              ret.push(' <i class="fa fa-refresh fa-status-small text-warning" title="', row.fence_history, '"></i>');
            }

            return ret.join('');
          }
        }, {
          field: 'name',
          title: __('Name'),
          sortable: false,
          switchable: false,
          clickToSelect: true
        }, {
          field: 'maintenance',
          title: __('Maintenance'),
          align: 'right',
          halign: 'right',
          sortable: false,
          clickToSelect: false,
          class: 'col-sm-1',
          events: {
            'click .ready': function (e, value, row, index) {
              e.preventDefault();
              $.hawkRunOperation(
                i18n.translate('This will bring node %s out of maintenance mode. Do you want to continue?').fetch(row.name),
                Routes.ready_cib_node_path($('body').data('cib'), row.id, { format: 'json' }));
              return false;
            },
            'click .maintenance': function (e, value, row, index) {
              e.preventDefault();

              $.hawkRunOperation(
                i18n.translate('This will put node %s in maintenance mode. All resources on this node will become unmanaged. Do you want to continue?').fetch(row.name),
                Routes.maintenance_cib_node_path($('body').data('cib'), row.id, { format: 'json' }));
              return false;
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
                '" class="ready btn btn-default btn-xs p-y-4" title="',
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
                '"class="maintenance btn btn-default btn-xs p-y-4" title="',
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
          clickToSelect: false,
          class: 'col-sm-1',
          align: 'right',
          halign: 'right',
          events: {
            'click .online': function (e, value, row, index) {
              e.preventDefault();
              $.hawkRunOperation(
                i18n.translate('This will bring node %s online if it is currently on standby. Do you want to continue?').fetch(row.name),
                Routes.online_cib_node_path($('body').data('cib'), row.id, { format: 'json' }));
              return false;
            },
            'click .standby': function (e, value, row, index) {
              e.preventDefault();
              $.hawkRunOperation(
                i18n.translate('This will put node %s on standby. All resources will be stopped and/or moved to another node. Do you want to continue?').fetch(row.name),
                Routes.standby_cib_node_path($('body').data('cib'), row.id, { format: 'json' }));
              return false;
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
                '" class="online btn btn-default btn-xs p-y-4" title="',
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
                '"class="standby btn btn-default btn-xs p-y-4" title="',
                __('Switch to standby'),
                '">',
                '<i class="fa fa-toggle-off text-success"></i>',
                '</a>'
              ].join('');
            }
          }
        }, {
          field: 'id',
          title: __('Operations'),
          sortable: false,
          clickToSelect: false,
          align: 'right',
          halign: 'right',
          class: 'col-sm-2',
          events: {
            'click .fence': function (e, value, row, index) {
              e.preventDefault();
              $.hawkRunOperation(
                i18n.translate('This will attempt to immediately fence node %s. Do you want to continue?').fetch(row.name),
                Routes.fence_cib_node_path($('body').data('cib'), row.id, { format: 'json' }));
              return false;
            },
            'click .clearstate': function (e, value, row, index) {
              e.preventDefault();
              $.hawkRunOperation(
                i18n.translate('Clear the state of node %s. The node is afterwards assumed clean and offline. This command can be used to manually confirm that a node has been fenced. Be careful! This can cause data corruption if the node is not cleanly down! Do you want to clear the state?').fetch(row.name),
                Routes.clearstate_cib_node_path($('body').data('cib'), row.id, { format: 'json' }));
              return false;
            }
          },
          formatter: function(value, row, index) {
            var operations = [];
            var dropdowns = [];

            var add_operation = function(dest, path, path_class, icon_class, text) {
              if (dest == "menu") {
                dropdowns.push([
                  '<li>',
                    '<a href="', path, '" class="', path_class, ' p-y-4">',
                      '<i class="fa fa-fw fa-', icon_class, '"></i> ',
                      text,
                    '</a>',
                  '</li>'
                ].join(''));
              } else if (dest == "button") {
                operations.push([
                  '<a href="', path, '" class="', path_class, ' p-y-4 btn btn-default btn-xs" title="', text, '">',
                    '<i class="fa fa-', icon_class, '"></i>',
                  '</a> '
                ].join(''));
              }
            };

            if (row.fence) {
              add_operation("menu", Routes.fence_cib_node_path($('body').data('cib'), row.id), 'fence', 'plug', __('Fence'));
              add_operation("menu", Routes.clearstate_cib_node_path($('body').data('cib'), row.id), 'clearstate', 'eraser', __('Clear state'));
              dropdowns.push(['<li role="separator" class="divider"></li>'].join(''));
            }

            add_operation("menu", Routes.edit_cib_node_path($('body').data('cib'), row.id), 'edit', 'pencil', __('Edit'));

            if (dropdowns.length > 0) {
              operations.push([
                '<div class="btn-group" role="group">',
                '<button class="btn btn-default btn-xs dropdown-toggle p-y-4" type="button" data-toggle="dropdown" data-container="body" aria-haspopup="true" aria-expanded="true">',
                '<i class="fa fa-caret-down" aria-hidden="true"></i>',
                '</button>',
                '<ul class="dropdown-menu">',
                dropdowns.join(''),
                '</ul>',
                '</div>'
              ].join(''));
            }

            operations.push([
              '<a href="',
              Routes.events_cib_node_path($('body').data('cib'), row.id),
              '"class="events btn btn-default btn-xs p-y-4" title="',
              __('Recent events'),
              '" data-toggle="modal" data-target="#modal-lg">',
              '<i class="fa fa-history"></i>',
              '</a> '
            ].join(''));

            operations.push([
              '<a href="',
              Routes.cib_node_path($('body').data('cib'), row.id),
              '"class="details btn btn-default btn-xs p-y-4" title="',
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

    $('#nodes #middle table.nodes, #configs #middle table.nodes')
    .bootstrapTable({
      method: 'get',
      url: Routes.cib_nodes_path(
        $('body').data('cib'),
        { format: 'json' }
      ),
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
      sortName: 'name',
      sortOrder: 'asc',
      striped: true,
      columns: [{
        field: 'name',
        title: __('Name'),
        class: 'col-sm-4',
        sortable: true,
        switchable: false,
        clickToSelect: true
      }, {
        field: 'id',
        title: __('ID'),
        sortable: true,
        switchable: false,
        clickToSelect: true
      }, {
        field: 'id',
        title: __('Operations'),
        sortable: false,
        clickToSelect: false,
        class: 'col-sm-2',
        align: 'right',
        halign: 'right',
        events: {
        },
        formatter: function(value, row, index) {
          var operations = [];

          operations.push([
            '<a href="',
             Routes.edit_cib_node_path($('body').data('cib'), row.id),
              '" class="edit btn btn-default btn-xs p-y-4" title="',
              __('Edit'),
            '">',
              '<i class="fa fa-pencil"></i>',
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


  $('#nodes #middle table.nodes, #cib #middle table.nodes, #configs #middle table.nodes').on("click", ".dropdown-toggle", function(event){
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
