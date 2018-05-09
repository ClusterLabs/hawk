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

  var agentLinkForResource = function(resource) {
    var cib = $('body').data('cib');
    if (resource.template && resource.template.length > 0) {
      return '<a href="' + Routes.cib_agent_path(cib, encodeURIComponent("@" + resource.template)) + '" data-toggle="modal" data-target="#modal-lg">' + "@" + resource.template + '</a>';
    }

    var agent = "";
    if (resource["class"]) {
      agent += resource["class"] + ":";
    }
    if (resource["provider"]) {
      agent += resource.provider + ":";
    }
    agent += resource.type;
    return '<a href="' + Routes.cib_agent_path(cib, encodeURIComponent(agent)) + '" data-toggle="modal" data-target="#modal-lg">' + agent + '</a>';
  };

  function resourceRoutes(row) {
    var cib = $('body').data('cib');
    var editRoute = null;
    var destroyRoute = null;
    var editNameRoute = Routes.edit_name_cib_resource_path(cib, row.id, { source: "edit"});
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
    return { edit: editRoute, destroy: destroyRoute, editName: editNameRoute };
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
        case "maintenance":
          fmt.push('<i class="fa fa-wrench fa-lg text-info" title="', __("Maintenance Mode"), '"></i>');
          break;
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
      title: __('Name'),
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
          var all_nodes = Object.keys(row.running_on);
          var masters = $.grep(all_nodes, function(n) { return row.running_on[n] == "master"; });
          var others = $.grep(all_nodes, function(n) { return row.running_on[n] != "master"; });
          if (others.length > 8) {
            others = others.slice(0, 8);
            others.push("...");
          }
          return $.map(masters, function(n) { return "<b>" + n + "</b>"; }).concat(others).join(", ");
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
      class: 'col-sm-2',
      formatter: function(value, row, index) {
        if (row.object_type == "group") {
          return __("Group") + " (" + row.children.length + ")";
        } else if (row.object_type == "master") {
          return __("Multi-state");
        } else if (row.object_type == "clone") {
          if (row.children.length > 0) {
            return agentLinkForResource(row.children[0]) + " (" + __("Clone") + ")";
          } else {
            return __("Clone");
          }
        } else if (row.object_type == "tag") {
          return __("Tag");
        } else if (row.object_type == "bundle") {
          return __("Bundle");
        } else if ("template" in row || ("class" in row && "provider" in row && "type" in row)) {
          return agentLinkForResource(row);
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
        'click .maintenance_on': function (e, value, row, index) {
          e.preventDefault();
          return executeAction($(this), i18n.translate('This will enable maintenance mode for resource %s. Do you want to continue?').fetch(row.id));
        },
        'click .maintenance_off': function (e, value, row, index) {
          e.preventDefault();
          return executeAction($(this), i18n.translate('This will disable maintenance mode for resource %s. Do you want to continue?').fetch(row.id));
        },
        'click .migrate': function (e, value, row, index) {
          e.preventDefault();
          return executeNodeSelectionAction($(this),
                                            i18n.translate('Migrate %s').fetch(row.id),
                                            __("Away from current node"));
        },
        'click .unmigrate': function (e, value, row, index) {
          e.preventDefault();
          return executeAction($(this), i18n.translate('This will remove any migration constraints for the resource %s. Do you want to continue?').fetch(row.id));
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

        var add_operation = function(dest, path, path_class, icon_class, text) {
          if (dest == "menu") {
            dropdowns.push([
              '<li>',
                '<a href="', path, '"class="', path_class, '">',
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

        if (row.state === "started" || row.state === "master" || row.state === "slave") {
          add_operation(op_destination, Routes.stop_cib_resource_path($('body').data('cib'), row.id), 'stop', 'stop', __('Stop'));
        }

        if (row.state === "stopped") {
          add_operation(op_destination, Routes.start_cib_resource_path($('body').data('cib'), row.id), 'start', 'play', __('Start'));
        }

        if (row.state === "master") {
          add_operation(op_destination, Routes.demote_cib_resource_path($('body').data('cib'), row.id), 'demote', 'thumbs-down', __('Demote'));
        }

        if (row.state === "slave") {
          add_operation(op_destination, Routes.promote_cib_resource_path($('body').data('cib'), row.id), 'promote', 'thumbs-up', __('Promote'));
        }

        if (row.maintenance === false) {
          add_operation("menu", Routes.maintenance_on_cib_resource_path($('body').data('cib'), row.id), 'maintenance_on', 'wrench', __('Maintenance'));
        } else {
          add_operation("button", Routes.maintenance_off_cib_resource_path($('body').data('cib'), row.id), 'maintenance_off', 'toggle-on', __('Disable Maintenance Mode'));
        }

        var rsc_routes = resourceRoutes(row);

        add_operation("menu", Routes.migrate_cib_resource_path($('body').data('cib'), row.id), 'migrate', 'arrows', __('Migrate'));
        if (resourceMigrationConstraints(row.id).length > 0) {
          add_operation("menu", Routes.unmigrate_cib_resource_path($('body').data('cib'), row.id), 'unmigrate', 'chain-broken', __('Clear'));
        }
        add_operation("menu", Routes.cleanup_cib_resource_path($('body').data('cib'), row.id), 'cleanup', 'eraser', __('Cleanup'));

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

        add_operation("menu", rsc_routes.edit, 'edit', 'pencil', __('Edit'));

        operations.push([
          '<div class="btn-group" role="group">',
            '<button class="btn btn-default btn-xs dropdown-toggle " type="button" data-toggle="dropdown" data-container="body" aria-haspopup="true" aria-expanded="true">',
              '<i class="fa fa-caret-down" aria-hidden="true"></i>',
            '</button>',
            '<ul class="dropdown-menu">',
              dropdowns.join(''),
            '</ul>',
          '</div>'
        ].join(''));

        operations.push([
          '<a href="',
          Routes.cib_resource_path($('body').data('cib'), row.id),
          '"class="details btn btn-default btn-xs " title="',
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
    }
  ];

  var rowStyleFn = function(row, index) {
    if (row.state == "unknown") {
      return {};
    } else if (row.state == "maintenance") {
      return { classes: ["info"] };
    } else if (row.state == "unmanaged") {
      return { classes: ["warning"] };
    } else if (row.state == "master") {
      return { classes: ["success"] };
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
          classes: "table table-striped reports table-hover",
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
          classes: "table table-striped reports table-hover",
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
        params.success(cib.resources, "success", {});
        params.complete({}, "success");
      },
      classes: "table table-striped reports table-hover",
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

  $('#cib #middle table.tagtable').each(function() {
    var tabletag = $(this);
    tabletag.bootstrapTable({
      ajax: function(params) {
        var cib = $('body').data('content');
        var tagname = tabletag.data('tagname');
        var taglst = $.grep(cib.tags, function(t) { return t.id == tagname; });
        if (taglst.length == 0) {
          params.error([], "error", {});
          params.complete({}, "error");
          return;
        }
        var tagdata = taglst[0];
        var matches = [];
        function recmatch(res) {
          if (tagdata.refs.indexOf(res.id) > -1) {
            matches.push(res);
          }
          if ("child" in res) {
            recmatch(res.child);
          }
          if ("children" in res) {
            for (var i = 0; i < res.children.length; i++) {
              recmatch(res.children[i]);
            }
          }
        }
        for (var i = 0; i < cib.resources.length; i++) {
          recmatch(cib.resources[i]);
        }
        params.success(matches, "success", {});
        params.complete({}, "success");
      },
      classes: "table table-striped reports table-hover",
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
      sortName: 'id',
      sortOrder: 'asc',
      striped: true,
      columns: [{
        field: 'id',
        title: __('Name'),
        class: 'col-sm-4',
        sortable: true,
        switchable: false,
        clickToSelect: true
      }, {
        field: 'sort_type',
        title: __('Type'),
        sortable: true,
        clickToSelect: true,
        class: 'col-sm-2',
        formatter: function(value, row, index) {
          if (row.object_type == "group") {
            return __("Group");
          } else if (row.object_type == "master") {
            return __("Multi-state");
          } else if (row.object_type == "clone") {
            return __("Clone");
          } else if (row.object_type == "tag") {
            return __("Tag");
          } else if (row.object_type == "bundle") {
            return __("Bundle");
          } else if (row.template && row.template.length > 0) {
            return '<a href="' + Routes.cib_agent_path($('body').data('cib'), encodeURIComponent("@" + row.template)) + '" data-toggle="modal" data-target="#modal-lg">' + value + '</a>';
          } else if ("clazz" in row && "provider" in row && "type" in row) {
            var agent = "";
            if (row["clazz"]) {
              agent += row["clazz"] + ":";
            }
            if (row["provider"]) {
              agent += row.provider + ":";
            }
            agent += row.type;
            var display = agent;
            if (row.object_type == 'template') {
              display = "Template (" + agent + ")";
            }
            return '<a href="' + Routes.cib_agent_path($('body').data('cib'), encodeURIComponent(agent)) + '" data-toggle="modal" data-target="#modal-lg">' + display + '</a>';
          } else {
            return row.type;
          }
        }
      }, {
        field: 'id',
        title: __('Children'),
        sortable: false,
        switchable: false,
        clickToSelect: false,
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
            $.hawkDeleteOperation(row.id, $(this).attr('href'));
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

          operations.push([
            '<a href="',
            rsc_routes.editName,
            '" class="rename btn btn-default btn-xs" title="',
            __('Rename'),
            '" data-toggle="modal" data-target="#modal">',
            '<i class="fa fa-font"></i>',
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

  $('#cib #middle table.resources, #cib #middle table.tagtable, #cib #middle .tag-controls').on("click", ".dropdown-toggle", function(event){
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

  $('#cib #middle .tab-pane .tag-controls').each(function() {
    $(this).on('click', '.start', function(e) {
      e.preventDefault();
      return executeAction($(this), __('This will start the tagged resources. Do you want to continue?'));
    }).on('click', '.stop', function(e) {
      e.preventDefault();
      return executeAction($(this), __('This will stop the tagged resources. Do you want to continue?'));
    }).on('click', '.promote', function(e) {
      e.preventDefault();
      return executeAction($(this), __('This will promote the tagged resources. Do you want to continue?'));
    }).on('click', '.demote', function(e) {
      e.preventDefault();
      return executeAction($(this), __('This will demote the tagged resources. Do you want to continue?'));
    }).on('click', '.maintenance_on', function(e) {
      e.preventDefault();
      return executeAction($(this), __('This will enable maintenance mode for the tagged resources. Do you want to continue?'));
    }).on('click', '.maintenance_off', function(e) {
      e.preventDefault();
      return executeAction($(this), __('This will disable maintenance mode for the tagged resources. Do you want to continue?'));
    }).on('click', '.migrate', function(e) {
      e.preventDefault();
      return executeNodeSelectionAction($(this),
                                        __('Migrate tagged resources'),
                                        __("Away from current node"));
    }).on('click', '.unmigrate', function(e) {
      e.preventDefault();
      return executeAction($(this), __('This will remove any migration constraints for the tagged resources. Do you want to continue?'));
    }).on('click', '.cleanup', function(e) {
      e.preventDefault();
      return executeNodeSelectionAction($(this),
                                        __('Clean up tagged resources'),
                                        __("Clean up on all nodes"));
    });
  });
});
