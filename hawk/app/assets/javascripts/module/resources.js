// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  function unique(list) {
    var result = [];
    $.each(list, function(i, e) {
      if ($.inArray(e, result) == -1) result.push(e);
    });
    return result;
  }
  // Returns list of nodes that the resource is started at
  var startedAt = function(row) {
    var ret = [];
    if ("instances" in row && "default" in row.instances) {
      if ("started" in row.instances["default"]) {
        $.each(row.instances["default"].started, function(i, v) {
          ret.push(v.node);
        });
      }
    }
    if ("children" in row) {
      $.each(row.children, function(i, v) {
        if ("instances" in v && "default" in v.instances) {
          if ("started" in v.instances["default"]) {
            $.each(v.instances["default"].started, function(i, v) {
              ret.push(v.node);
            });
          }
        }
      });
    }
    return unique(ret);
  };
  var stateString = function(row) {
    if (!row.is_managed) {
      return "unmanaged";
    } else {
      var starts = startedAt(row);
      console.log(row.id + " starts:", starts);
      if (starts.length > 0)
        return "started";
    }
    return "stopped";
  };

  $('#states #middle table.resources')
    .bootstrapTable({
      method: 'get',
      url: Routes.status_cib_resources_path(
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
      sortName: 'id',
      sortOrder: 'asc',
      columns: [
        {
          field: 'state',
          title: __('Status'),
          sortable: true,
          clickToSelect: true,
          class: 'col-sm-1',
          formatter: function(value, row, index) {
            var state = stateString(row);
            if (state == "unmanaged") {
              return [
                '<i class="fa fa-exclamation-triangle text-warning" title="',
                __("Unmanaged"),
                '"></i>'
              ].join('');
            } else if (state == "started") {
              return [
                '<i class="fa fa-play text-success" title="',
                __("Started"),
                '"></i>'
              ].join('');
            } else {
              return [
                '<i class="fa fa-stop text-danger" title="',
                __("Stopped"),
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
            return startedAt(row).join(", ");
          }
        },
        {
          field: 'type',
          title: __('Type'),
          sortable: true,
          clickToSelect: true,
          class: 'col-sm-1',
          formatter: function(value, row, index) {
            if (row.type == "group") {
              return __("Group");
            } else if (row.type == "master") {
              return __("Multi-state");
            } else if (row.type == "clone") {
              return __("Clone");
            } else if (row.template != null) {
              return '<a href="' + Routes.agent_path({id: "@" + row.template}) + '" data-toggle="modal" data-target="#modal-lg">' + "@" + row.template + '</a>';
            } else if ("class" in row && "provider" in row && "type" in row) {
              var agent = "";
              if (row["class"])
              agent += row["class"] + ":";
              if (row["provider"])
              agent += row.provider + ":";
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
          formatter: function(value, row, index) {
            var operations = [];

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
        }]
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
      showColumns: true,
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

          switch(row.object_type) {
            case "primitive":
              var editRoute = Routes.edit_cib_primitive_path(
                $('body').data('cib'),
                row.id
              );

              var deleteRoute = Routes.cib_primitive_path(
                $('body').data('cib'),
                row.id
              );

              break;
            case "group":
              var editRoute = Routes.edit_cib_group_path(
                $('body').data('cib'),
                row.id
              );

              var deleteRoute = Routes.cib_group_path(
                $('body').data('cib'),
                row.id
              );

              break;
            case "clone":
              var editRoute = Routes.edit_cib_clone_path(
                $('body').data('cib'),
                row.id
              );

              var deleteRoute = Routes.cib_clone_path(
                $('body').data('cib'),
                row.id
              );

              break;
            case "master":
              var editRoute = Routes.edit_cib_master_path(
                $('body').data('cib'),
                row.id
              );

              var deleteRoute = Routes.cib_master_path(
                $('body').data('cib'),
                row.id
              );

              break;
            case "tag":
              var editRoute = Routes.edit_cib_tag_path(
                $('body').data('cib'),
                row.id
              );

              var deleteRoute = Routes.cib_tag_path(
                $('body').data('cib'),
                row.id
              );

              break;
            default:
              var editRoute = Routes.edit_cib_resource_path(
                $('body').data('cib'),
                row.id
              );

              var deleteRoute = Routes.cib_resource_path(
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
