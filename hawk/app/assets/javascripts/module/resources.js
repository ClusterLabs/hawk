// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  function executeAction(context, confirmMsg) {
    $.hawkRunOperation(confirmMsg, [context.attr('href'), ".json"].join(""));
    return false;
  }

  function executeNodeSelectionAction(context, message, defaultmsg) {
    var html = [
      '<div class="modal fade" id="nodeSelectionDialog" role="dialog" tabindex="-1" aria-hidden="true">',
      '<div class="modal-dialog">',
      '<div class="modal-content">',
      '<form class="form-horizontal" role="form" onsubmit="return false;">',
      '<div class="modal-header">',
      '<button class="close" type="button" data-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only">', __('Close'), '</span></button>',
      '<div class="text-center">', message,
      '</div>',
      '</div>',
      '<div class="modal-body">',
      '<select id="nodeSel" class="form-control">',
      '<option value="">',
      defaultmsg,
      '</option>',
    ];

    var cib = $('body').data('content');

    $.each(cib.nodes, function(index, node) {
      html.push(
        '<option value="', node.name, '">',
        node.name,
        '</option>'
      );
    });

    html.push(
      '</select>',
      '</div>',
      '<div class="modal-footer">',
      '<button class="btn btn-default cancel" data-dismiss="modal">', __('Cancel'),'</button>',
      '<button class="btn btn-primary commit" data-dismiss="modal">', __('OK'),'</button>',
      '</div>',
      '</form>',
      '</div>',
      '</div>',
      '</div>'
    );

    var applyFunction = function(dialog) {
      var nodename = dialog.find('#nodeSel').val();
      var url = "";
      if (nodename.length > 0) {
        url = [
          context.attr('href'),
          ".json",
          '?node=',
          encodeURIComponent(nodename)
        ].join("");
      } else {
        url = [ context.attr('href'), ".json" ].join("");
      }
      $.ajax({
        dataType: 'json',
        method: 'GET',
        url: url,
        success: function(data) {
          if (data.success) {
            $.growl({
              message: data.message
            },{
              type: 'success'
            });
          } else {
            if (data.error) {
              $.growl({
                message: data.error
              },{
                type: 'danger'
              });
            }
          }
          $.runSimulator();
        },
        error: function(xhr, status, msg) {
          $.growl({
            message: xhr.responseJSON.error || msg
          },{
            type: 'danger'
          });
          $.runSimulator();
        }
      });
    };

    var modal = $(html.join(''));
    modal.css('z-index', 100000);
    modal.find('.commit').on('click', function() {
      var dialog = $('#nodeSelectionDialog');
      applyFunction(dialog);
      dialog.modal('hide');
      return true;
    });

    modal.on('hidden.bs.modal', function () {
      modal.remove();
    });

    $('body').append(modal);
    modal.modal();

    return false;
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
    case "template":
      editRoute = Routes.edit_cib_template_path(cib, row.id);
      destroyRoute = Routes.cib_template_path(cib, row.id);
      break;
    default:
      editRoute = Routes.edit_cib_resource_path(cib, row.id);
      destroyRoute = Routes.cib_resource_path(cib, row.id);
      break;
    }
    return { edit: editRoute, destroy: destroyRoute };
  }

  function startswith(str, prefix) {
    return str.substr(0, prefix.length) === prefix;
  }

  function resourceMigrationConstraints(rsc) {
    var cib = $('body').data('content');
    var ban = "cli-ban-" + rsc + "-on-";
    var prefer = "cli-prefer-" + rsc;
    var ret = [];
    $.each(cib.constraints, function(i, c) {
      if (c.id == prefer || startswith(c.id, ban)) {
        ret.push(c.id);
      }
    });
    return ret;
  }

  var statesResourcesColumns = [
    {
      field: 'state',
      title: __('Status'),
      sortable: false,
      clickToSelect: false,
      align: "center",
      halign: "center",
      class: 'col-sm-1',
      formatter: function(value, row, index) {
        var fmt = [];
        switch(value) {
        case "unmanaged":
          fmt.push('<i class="fa fa-exclamation-triangle fa-lg text-warning" title="', __("Unmanaged"), '"></i>');
          break;
        case "started":
          fmt.push('<i class="fa fa-circle fa-lg text-success" title="', __("Started"), '"></i>');
          break;
        case "master":
          fmt.push('<i class="fa fa-circle fa-lg text-info" title="', __("Primary"), '"></i>');
          break;
        case "slave":
          fmt.push('<i class="fa fa-dot-circle-o fa-lg text-success" title="', __("Secondary"), '"></i>');
          break;
        case "stopped":
          fmt.push('<i class="fa fa-minus-circle fa-lg text-danger" title="', __("Stopped"), '"></i>');
          break;
        default:
          fmt.push('<i class="fa fa-question fa-lg text-warning" title="', value, '"></i>');
          break;
        }
        $.each(resourceMigrationConstraints(row.id), function(i, c) {
          fmt.push('<i class="fa fa-link fa-status-small text-info" title="', c, '"></i>');
        });
        return fmt.join("");
      }
    },
    {
      field: 'id',
      title: __('ID'),
      sortable: false,
      clickToSelect: false,
      class: 'col-sm-2'
    },
    {
      field: 'running_on',
      title: __('Location'),
      sortable: false,
      clickToSelect: false,
      class: 'col-sm-6',
      formatter: function(value, row, index) {
        if ("running_on" in row) {
          var nodes = Object.keys(row.running_on);
          if (nodes.length > 8) {
            nodes = nodes.slice(0, 8);
            nodes.push("...");
          }
          return nodes.join(", ");
        } else {
          return "";
        }
      }
    },
    {
      field: 'type',
      title: __('Type'),
      sortable: false,
      clickToSelect: false,
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
          return '<a href="' + Routes.cib_agent_path($('body').data('cib'), encodeURIComponent("@" + row.template)) + '" data-toggle="modal" data-target="#modal-lg">' + "@" + row.template + '</a>';
        } else if ("class" in row && "provider" in row && "type" in row) {
          var agent = "";
          if (row["class"]) {
            agent += row["class"] + ":";
          }
          if (row["provider"]) {
            agent += row.provider + ":";
          }
          agent += row.type;
          return '<a href="' + Routes.cib_agent_path($('body').data('cib'), encodeURIComponent(agent)) + '" data-toggle="modal" data-target="#modal-lg">' + row.type + '</a>';
        } else {
          return row.type;
        }
      }
    },
    {
      field: 'id',
      title: __('Operations'),
      sortable: false,
      clickToSelect: false,
      align: 'right',
      halign: 'right',
      class: 'col-sm-2',
      events: {
        'click .start': function (e, value, row, index) {
          e.preventDefault();
          return executeAction($(this), i18n.translate('This will start the resource %s. Do you want to continue?').fetch(row.id));
        },
        'click .stop': function (e, value, row, index) {
          e.preventDefault();
          return executeAction($(this), i18n.translate('This will stop the resource %s. Do you want to continue?').fetch(row.id));
        },
        'click .promote': function (e, value, row, index) {
          e.preventDefault();
          return executeAction($(this), i18n.translate('This will promote the resource %s. Do you want to continue?').fetch(row.id));
        },
        'click .demote': function (e, value, row, index) {
          e.preventDefault();
          return executeAction($(this), i18n.translate('This will demote the resource %s. Do you want to continue?').fetch(row.id));
        },
        'click .manage': function (e, value, row, index) {
          e.preventDefault();
          return executeAction($(this), i18n.translate('This will manage the resource %s. Do you want to continue?').fetch(row.id));
        },
        'click .unmanage': function (e, value, row, index) {
          e.preventDefault();
          return executeAction($(this), i18n.translate('This will unmanage the resource %s. Do you want to continue?').fetch(row.id));
        },
        'click .migrate': function (e, value, row, index) {
          e.preventDefault();
          return executeNodeSelectionAction($(this),
                                            i18n.translate('Migrate %s').fetch(row.id),
                                            __("Away from current node"));
        },
        'click .unmigrate': function (e, value, row, index) {
          e.preventDefault();
          return executeAction($(this), i18n.translate('This will unmigrate the resource %s. Do you want to continue?').fetch(row.id));
        },
        'click .cleanup': function (e, value, row, index) {
          e.preventDefault();
          return executeNodeSelectionAction($(this),
                                            i18n.translate('Clean up %s').fetch(row.id),
                                            __("Clean up on all nodes"));
        }
      },
      formatter: function(value, row, index) {
        var operations = [];
        var dropdowns = [];

        var op_destination = "button";
        if (row.object_type == "tag") {
          op_destination = "menu";
        }

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

        if (row.state === "started" || row.state === "master" || row.state === "slave" || row.object_type == "tag") {
          add_operation(op_destination, Routes.stop_cib_resource_path($('body').data('cib'), row.id), 'stop', 'stop', __('Stop'));
        }

        if (row.state === "stopped" || row.object_type == "tag") {
          add_operation(op_destination, Routes.start_cib_resource_path($('body').data('cib'), row.id), 'start', 'play', __('Start'));
        }

        if (row.state === "master" || row.object_type == "tag") {
          add_operation(op_destination, Routes.demote_cib_resource_path($('body').data('cib'), row.id), 'demote', 'thumbs-down', __('Demote'));
        }

        if (row.state === "slave" || row.object_type == "tag") {
          add_operation(op_destination, Routes.promote_cib_resource_path($('body').data('cib'), row.id), 'promote', 'thumbs-up', __('Promote'));
        }

        if (row.is_managed === true) {
          add_operation("menu", Routes.unmanage_cib_resource_path($('body').data('cib'), row.id), 'unmanage', 'circle', __('Unmanage'));
        }

        if (row.is_managed === false) {
          add_operation("menu", Routes.manage_cib_resource_path($('body').data('cib'), row.id), 'manage', 'dot-circle-o', __('Manage'));
        }

        var rsc_routes = resourceRoutes(row);

        add_operation("menu", Routes.migrate_cib_resource_path($('body').data('cib'), row.id), 'migrate', 'arrows', __('Migrate'));
        if (resourceMigrationConstraints(row.id).length > 0) {
          add_operation("menu", Routes.unmigrate_cib_resource_path($('body').data('cib'), row.id), 'unmigrate', 'chain-broken', __('Unmigrate'));
        }
        add_operation("menu", Routes.cleanup_cib_resource_path($('body').data('cib'), row.id), 'cleanup', 'eraser', __('Cleanup'));

        if (row.object_type == "tag") {
          dropdowns.push([
            '<li role="separator" class="divider"></li>'
          ].join(''));
        } else {
          dropdowns.push([
            '<li role="separator" class="divider"></li>',
            '<li>',
            '<a href="',
            Routes.events_cib_resource_path($('body').data('cib'), row.id),
            '" class="events" data-toggle="modal" data-target="#modal-lg">',
            '<i class="fa fa-fw fa-history"></i> ',
            __('Recent events'),
            '</a>',
            '</li>',
            '<li role="separator" class="divider"></li>'
          ].join(''));
        }

        add_operation("menu", rsc_routes.edit, 'edit', 'pencil', __('Edit'));

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

        if (row.object_type != "tag") {
          operations.push([
            '<a href="',
            Routes.cib_resource_path($('body').data('cib'), row.id),
            '" class="details btn btn-default btn-xs" title="',
            __('Details'),
            '" data-toggle="modal" data-target="#modal">',
            '<i class="fa fa-search"></i>',
            '</a> '
          ].join(''));
        }

        return [
          '<div class="btn-group" role="group">',
          operations.join(''),
          '</div>',
        ].join('');
      }
    }
  ];

  var rowStyleFn = function(row, index) {
    if (row.state == "unknown") {
      return {};
    } else if (row.state == "unmanaged") {
      return { classes: ["warning"] };
    } else if (row.state == "master") {
      return { classes: ["info"] };
    } else if (row.state == "slave") {
      return { classes: ["success"] };
    } else if (row.state == "started") {
      return { classes: ["success"] };
    } else if (row.state == "stopped") {
      return {};
    } else {
      return { classes: ["danger"] };
    }
  };

  // filter out tags without any resource children
  var filterTags = function(resources_by_id, tags) {
    return $.grep(tags, function(tag) {
      if ("refs" in tag) {
        var rscrefs = $.grep(tag.refs, function(ref) {
          return ref in resources_by_id;
        });
        return rscrefs.length > 0;
      }
      return true;
    });
  };

  var expandResourcesHandler = function (index, row, detail) {
    var columns = statesResourcesColumns.slice(0);
    var datasource = [];
    if (row.children || row.child || row.refs) {
      var datasource = [];
      if (row.children) {
        datasource = row.children;
      } else if (row.child) {
        datasource = [row.child];
      } else {
        var cib = $('body').data('content');
        datasource = $.grep($.map(row.refs, function(ref) {
          if (ref in cib.resources_by_id) {
            return cib.resources_by_id[ref];
          } else {
            var ret = null;
            $.each(cib.tags, function(i, o) {
              if (o.id == ref) {
                ret = o;
              }
            });
            return ret;
          }
        }), function(o) { return o !== null; });
      }
    }

    if (datasource.length == 0) {
      detail.html(['<div class="text-center text-muted">', __("No child resources"), '</div>'].join(''));
      return;
    }

    var childwithchildren = false;
    $.each(datasource, function(_idx, child) {
      if ("child" in child || "children" in child) {
        childwithchildren = true;
      }
    });

    if (childwithchildren) {
      detail
        .html('<table></table>')
        .find('table')
        .bootstrapTable({
          data: datasource,
          pagination: false,
          smartDisplay: false,
          showColumns: false,
          showRefresh: false,
          showHeader: false,
          showFooter: false,
          rowStyle: rowStyleFn,
          minimumCountColumns: 0,
          sortName: 'id',
          sortOrder: 'asc',
          detailView: true,
          onExpandRow: expandResourcesHandler,
          columns: columns
        });
    } else {
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
          pagination: false,
          smartDisplay: false,
          showColumns: false,
          showRefresh: false,
          showHeader: false,
          showFooter: false,
          rowStyle: rowStyleFn,
          minimumCountColumns: 0,
          sortName: 'id',
          sortOrder: 'asc',
          columns: columns
        });
    }
  };

  $('#cib #middle table.resources')
    .bootstrapTable({
      ajax: function(params) {
        var cib = $('body').data('content');
        var resources_and_tags = cib.resources.concat(filterTags(cib.resources_by_id, cib.tags));
        params.success(resources_and_tags, "success", {});
        params.complete({}, "success");
      },
      classes: "table table-hover table-no-bordered",
      pagination: false,
      pageSize: 25,
      pageList: [10, 25, 50, 100, 200],
      sidePagination: 'client',
      smartDisplay: false,
      search: false,
      searchAlign: 'left',
      striped: false,
      showColumns: false,
      showRefresh: false,
      minimumCountColumns: 0,
      sortName: 'id',
      sortOrder: 'asc',
      detailView: true,
      rowStyle: rowStyleFn,
      onExpandRow: expandResourcesHandler,
      columns: statesResourcesColumns
    });

  $('#resources #middle table.resources, #configs #middle table.resources')
    .bootstrapTable({
      method: 'get',
      url: Routes.cib_resources_path(
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
      sortName: 'object_type',
      sortOrder: 'asc',
      striped: true,
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
            case "group":
              return __("Group");
            case "clone":
              return __("Clone");
            case "master":
              return __("Multi-state");
            case "tag":
              return __("Tag");
            case "template":
              return __("Template");
            default:
              return row.object_type;
          }
        }
      }, {
        field: 'id',
        title: __('Resource'),
        sortable: true,
        switchable: false,
        clickToSelect: true
      }, {
        field: 'id',
        title: __('Resources'),
        sortable: true,
        switchable: false,
        clickToSelect: true,
        formatter: function(value, row, index) {
          if ("child" in row) {
            return row.child;
          } else if ("children" in row) {
            return row.children.join(", ");
          } else if ("refs" in row) {
            return row.refs.join(", ");
          } else {
            return "";
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
            $.hawkDeleteOperation(row.id, [$(this).attr('href'), ".json"].join(""));
            return false;
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

          if (row.object_type != "tag") {
            operations.push([
              '<a href="',
              Routes.rename_cib_resource_path($('body').data('cib'), row.id),
              '" class="rename btn btn-default btn-xs" title="',
              __('Rename'),
              '" data-toggle="modal" data-target="#modal">',
              '<i class="fa fa-font"></i>',
              '</a> '
            ].join(''));
          }

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

  $('#cib #middle table.resources').on("click", ".dropdown-toggle", function(event){
    var button = $(this);
    var open = button.attr('aria-expanded');
    var dropdown = button.siblings('.dropdown-menu');
    if (open) {
      dropdown.css('top', (button.offset().top - $(window).scrollTop() + button.outerHeight()) + "px");
      dropdown.css('left', (button.offset().left + button.outerWidth() - dropdown.outerWidth()) + "px");
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
