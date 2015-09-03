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

    $('#resources #middle table.resources, #states #middle table.resources')
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
                    title: __('Resource'),
                    sortable: true,
                    switchable: false,
                    clickToSelect: true
                },
                {
                    field: 'type',
                    title: __('Type'),
                    sortable: true,
                    clickToSelect: true,
                    formatter: function(value, row, index) {
                        if (row.type == "group") {
                          return __("Group");
                        } else if (row.type == "master") {
                          return __("Multi-state");
                        } else if (row.type == "clone") {
                          return __("Clone");
                        } else if (row.template != null) {
                          return '<a href="' + Routes.agent_path("@" + row.template) + '" data-toggle="modal" data-target="#modal-lg">' + "@" + row.template + '</a>';
                        } else if ("class" in row && "provider" in row && "type" in row) {
                          var agent = "";
                          if (row["class"])
                            agent += row["class"] + ":";
                          if (row["provider"])
                            agent += row.provider + ":";
                          agent += row.type;
                          return '<a href="' + Routes.agent_path(agent) + '" data-toggle="modal" data-target="#modal-lg">' + row.type + '</a>';
                        } else {
                          return row.type;
                        }
                    }
                },
                {
                    field: 'type',
                    title: __('Location'),
                    sortable: true,
                    clickToSelect: true,
                    formatter: function(value, row, index) {
                        return startedAt(row).join(", ");
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
