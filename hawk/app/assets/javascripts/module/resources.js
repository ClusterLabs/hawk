// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  function executeAction(context, confirmMsg) {
    try {
      answer = confirm(
        confirmMsg
      );
    } catch (e) {
      (console.error || console.log).call(console, e.stack || e);
    }

    if (answer) {
      $.ajax({
        dataType: 'json',
        method: 'GET',
        url: [
          context.attr('href'),
          ".json"
        ].join(""),

        success: function(data) {
          if (data.success) {
            $.growl({
              message: data.message
            },{
              type: 'success'
            });

            context.parents('table').bootstrapTable('refresh')
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

  function resourceRoutes(row) {
    var editRoute = null;
    var destroyRoute = null;
    var cib = $('body').data('cib');
    switch(row.object_type) {
    case "primitive":
      editRoute = Routes.edit_cib_primitive_path(cib, row.id);
      destroyRoute = Routes.cib_primitive_path(cib, row.id);
      break;
    case "group":
      editRoute = Routes.edit_cib_group_path(cib, row.id);
      destroyRoute = Routes.cib_group_path(cib, row.id);
      break;
    case "clone":
      editRoute = Routes.edit_cib_clone_path(cib, row.id);
      destroyRoute = Routes.cib_clone_path(cib, row.id);
      break;
    case "master":
      editRoute = Routes.edit_cib_master_path(cib, row.id);
      destroyRoute = Routes.cib_master_path(cib, row.id);
      break;
    case "tag":
      editRoute = Routes.edit_cib_tag_path(cib, row.id);
      destroyRoute = Routes.cib_tag_path(cib, row.id);
      break;
    default:
      editRoute = Routes.edit_cib_resource_path(cib, row.id);
      destroyRoute = Routes.cib_resource_path(cib, row.id);
      break;
    }
    return { edit: editRoute, destroy: destroyRoute };
  }

  var statesResourcesColumns = [
    {
      field: 'state',
      title: __('Status'),
      sortable: true,
      clickToSelect: true,
      class: 'col-sm-1',
      formatter: function(value, row, index) {
        switch(value) {
          case "unknown":
            return '';
          case "unmanaged":
            return [
              '<i class="fa fa-exclamation-triangle fa-lg text-warning" title="',
              __("Unmanaged"),
              '"></i>'
            ].join('');
          case "started":
            return [
              '<i class="fa fa-play fa-lg text-success" title="',
              __("Started"),
              '"></i>'
            ].join('');
          case "master":
            return [
              '<i class="fa fa-circle fa-lg text-info" title="',
              __("Primary"),
              '"></i>'
            ].join('');
          case "slave":
            return [
              '<i class="fa fa-dot-circle-o fa-lg text-success" title="',
              __("Secondary"),
              '"></i>'
            ].join('');
          case "stopped":
            return [
              '<i class="fa fa-stop fa-lg text-danger" title="',
              __("Stopped"),
              '"></i>'
            ].join('');
          default:
            return [
              '<i class="fa fa-question-circle fa-lg text-warning" title="',
              value,
              '"></i>'
            ].join('');
        }
      }
    },
    {
      field: 'id',
      title: __('Name'),
      sortable: true,
      switchable: false,
      clickToSelect: true,
      class: 'col-sm-2'
    },
    {
      field: 'type',
      title: __('Location'),
      sortable: true,
      clickToSelect: true,
      class: 'col-sm-6',
      formatter: function(value, row, index) {
        if ("running_on" in row) {
          return Object.keys(row.running_on).join(", ");
        } else {
          return "";
        }
      }
    },
    {
      field: 'type',
      title: __('Type'),
      sortable: true,
      clickToSelect: true,
      class: 'col-sm-1',
      formatter: function(value, row, index) {
        if (row.object_type == "group") {
          return __("Group");
        } else if (row.object_type == "master") {
          return __("Multi-state");
        } else if (row.object_type == "clone") {
          return __("Clone");
        } else if (row.object_type == "tag") {
          return __("Tag");
        } else if (row.template && row.template.length > 0) {
          return '<a href="' + Routes.agent_path({id: "@" + row.template}) + '" data-toggle="modal" data-target="#modal-lg">' + "@" + row.template + '</a>';
        } else if ("clazz" in row && "provider" in row && "type" in row) {
          var agent = "";
          if (row["clazz"]) {
            agent += row["clazz"] + ":";
          }
          if (row["provider"]) {
            agent += row.provider + ":";
          }
          agent += row.type;
          return '<a href="' + Routes.agent_path({id: agent}) + '" data-toggle="modal" data-target="#modal-lg">' + row.type + '</a>';
        } else {
          return row.type;
        }
      }
    },
    {
      field: 'operate',
      title: __('Operations'),
      sortable: false,
      clickToSelect: false,
      class: 'col-sm-2',
      events: {
        'click .start': function (e, value, row, index) {
          e.preventDefault();

          executeAction(
            $(this),
            i18n.translate(
              'This will start the resource %s. Do you want to continue?'
            ).fetch(row.id)
          );
        },
        'click .stop': function (e, value, row, index) {
          e.preventDefault();

          executeAction(
            $(this),
            i18n.translate(
              'This will stop the resource %s. Do you want to continue?'
            ).fetch(row.id)
          );
        },
        'click .promote': function (e, value, row, index) {
          e.preventDefault();

          executeAction(
            $(this),
            i18n.translate(
              'This will promote the resource %s. Do you want to continue?'
            ).fetch(row.id)
          );
        },
        'click .demote': function (e, value, row, index) {
          e.preventDefault();

          executeAction(
            $(this),
            i18n.translate(
              'This will demote the resource %s. Do you want to continue?'
            ).fetch(row.id)
          );
        },
        'click .manage': function (e, value, row, index) {
          e.preventDefault();

          executeAction(
            $(this),
            i18n.translate(
              'This will manage the resource %s. Do you want to continue?'
            ).fetch(row.id)
          );
        },
        'click .unmanage': function (e, value, row, index) {
          e.preventDefault();

          executeAction(
            $(this),
            i18n.translate(
              'This will unmanage the resource %s. Do you want to continue?'
            ).fetch(row.id)
          );
        },
        'click .migrate': function (e, value, row, index) {
          e.preventDefault();

          executeAction(
            $(this),
            i18n.translate(
              'This will migrate the resource %s. Do you want to continue?'
            ).fetch(row.id)
          );
        },
        'click .unmigrate': function (e, value, row, index) {
          e.preventDefault();

          executeAction(
            $(this),
            i18n.translate(
              'This will unmigrate the resource %s. Do you want to continue?'
            ).fetch(row.id)
          );
        },
        'click .cleanup': function (e, value, row, index) {
          e.preventDefault();

          executeAction(
            $(this),
            i18n.translate(
              'This will cleanup the resource %s. Do you want to continue?'
            ).fetch(row.id)
          );
        }
      },
      formatter: function(value, row, index) {
        var operations = [];
        var dropdowns = [];

        if (row.state === "started" || row.state === "master" || row.state === "slave" || row.object_type == "tag") {
          dropdowns.push([
            '<li>',
              '<a href="',
              Routes.stop_cib_resource_path(
                $('body').data('cib'),
                row.id
              ),
              '" class="stop">',
                '<i class="fa fa-stop"></i> ',
                __('Stop'),
              '</a>',
            '</li>'
          ].join(''));
        }

        if (row.state === "stopped" || row.object_type == "tag") {
          dropdowns.push([
            '<li>',
              '<a href="',
              Routes.start_cib_resource_path(
                $('body').data('cib'),
                row.id
              ),
              '" class="start">',
                '<i class="fa fa-play"></i> ',
                __('Start'),
              '</a>',
            '</li>'
          ].join(''));
        }

        if (row.state === "master" || row.object_type == "tag") {
          dropdowns.push([
            '<li>',
              '<a href="',
              Routes.demote_cib_resource_path(
                $('body').data('cib'),
                row.id
              ),
              '" class="demote">',
                '<i class="fa fa-thumbs-down"></i> ',
                __('Demote'),
              '</a>',
            '</li>'
          ].join(''));
        }

        if (row.state === "slave" || row.object_type == "tag") {
          dropdowns.push([
            '<li>',
              '<a href="',
              Routes.promote_cib_resource_path(
                $('body').data('cib'),
                row.id
              ),
              '" class="promote">',
                '<i class="fa fa-thumbs-up"></i> ',
                __('Promote'),
              '</a>',
            '</li>'
          ].join(''));
        }

        if (row.managed === true) {
          dropdowns.push([
            '<li>',
              '<a href="',
              Routes.unmanage_cib_resource_path(
                $('body').data('cib'),
                row.id
              ),
              '" class="unmanage">',
                '<i class="fa fa-circle"></i> ',
                __('Unmanage'),
              '</a>',
            '</li>'
          ].join(''));
        }

        if (row.managed === false) {
          dropdowns.push([
            '<li>',
              '<a href="',
              Routes.manage_cib_resource_path(
                $('body').data('cib'),
                row.id
              ),
              '" class="manage">',
                '<i class="fa fa-dot-circle-o"></i> ',
                __('Manage'),
              '</a>',
            '</li>'
          ].join(''));
        }

        dropdowns.push([
          '<li>',
            '<a href="',
            Routes.migrate_cib_resource_path(
              $('body').data('cib'),
              row.id
            ),
            '" class="migrate">',
              '<i class="fa fa-hand-o-up"></i> ',
              __('Migrate'),
            '</a>',
          '</li>'
        ].join(''));

        dropdowns.push([
          '<li>',
            '<a href="',
            Routes.unmigrate_cib_resource_path(
              $('body').data('cib'),
              row.id
            ),
            '" class="unmigrate">',
              '<i class="fa fa-hand-o-down"></i> ',
              __('Unmigrate'),
            '</a>',
          '</li>'
        ].join(''));

        dropdowns.push([
          '<li>',
            '<a href="',
            Routes.cleanup_cib_resource_path(
              $('body').data('cib'),
              row.id
            ),
            '" class="cleanup">',
              '<i class="fa fa-eraser"></i> ',
              __('Cleanup'),
            '</a>',
          '</li>'
        ].join(''));

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

        var rsc_routes = resourceRoutes(row);

        operations.push([
          '<a href="',
            rsc_routes.edit,
            '" class="edit btn btn-default btn-xs" title="',
            __('Edit'),
          '">',
            '<i class="fa fa-pencil"></i>',
          '</a> '
        ].join(''));

        operations.push([
          '<a href="',
          Routes.cib_resource_path(
            $('body').data('cib'),
            row.id
          ),
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
    }
  ];

  $('#states #middle table.resources')
    .bootstrapTable({
      method: 'get',
      url: Routes.status_cib_resources_path(
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
      detailView: true,
      onExpandRow: function (index, row, detail) {
        if (row.children || row.child || row.refs) {
          var columns = statesResourcesColumns.slice(0);
          var datasource = [];
          if (row.children) {
            datasource = row.children;
          } else if (row.child) {
            datasource = [row.child];
          } else {
              datasource = row.refs;
          }

          columns.unshift({
            sortable: false,
            switchable: false,
            clickToSelect: false,
            formatter: function(value, row, index) {
              return '<i class="glyphicon glyphicon-arrow-right"></i>';
            }
          });

          detail
            .html('<table></table>')
            .find('table')
            .bootstrapTable({
              data: datasource,
              striped: true,
              pagination: false,
              smartDisplay: false,
              showColumns: false,
              showRefresh: false,
              showHeader: false,
              showFooter: false,
              minimumCountColumns: 0,
              sortName: 'id',
              sortOrder: 'asc',
              columns: columns
            });
        }
      },
      columns: statesResourcesColumns
    });

  $('#resources #middle table.resources')
    .bootstrapTable({
      method: 'get',
      url: Routes.cib_resources_path(
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
            case "primitive":
              return __("Primitive");
              break;
            case "group":
              return __("Group");
              break;
            case "clone":
              return __("Clone");
              break;
            case "master":
              return __("Multi-state");
              break;
            case "tag":
              return __("Tag");
              break;
            default:
              return row.object_type;
              break;
          }
        }
      }, {
        field: 'id',
        title: __('Resource'),
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
            }
          }
        },
        formatter: function(value, row, index) {
          var operations = [];

          var rsc_routes = resourceRoutes(row);

          operations.push([
            '<a href="',
              rsc_routes.edit,
              '" class="edit btn btn-default btn-xs" title="',
              __('Edit'),
            '">',
              '<i class="fa fa-pencil"></i>',
            '</a> '
          ].join(''));

          operations.push([
            '<a href="',
              rsc_routes.destroy,
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

  $('#states #middle table.resources').on("click", ".dropdown-toggle", function(event){
    var button = $(this);
    var open = button.attr('aria-expanded');
    var dropdown = button.siblings('.dropdown-menu');
    if (open) {
      dropdown.css('top', button.offset().top - $(window).scrollTop() + button.outerHeight() + "px");
      dropdown.css('left', button.offset().left + "px");
      dropdown.css('position', 'fixed');
    }
  });

  $('#resources #middle form')
    .validate({
      rules: {
        'node[id]': {
          minlength: 1,
          required: true
        }
      }
    });
});
