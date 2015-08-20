// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
    var description = function(row) {
        switch (row.type) {
        case 'rsc_location':
            var rsc = "";
            if ("children" in row) {
                var rscs = [];
                $.each(row.children, function(i, e) {
                    if ("children" in e) {
                        $.each(e.children, function(i, e) {
                            rscs.push(e.id);
                        });
                    }
                });
                rsc = rscs.join(", ");
            } else {
                rsc = row.rsc;
            }

            if (row.score == "INFINITY") {
                return rsc + " " + __("on") + " " + row.node;
            } else if (row.score == "-INFINITY") {
                return rsc + " " + __("never on") + " " + row.node;
            } else if (row.score[0].match(/^-/)) {
                return rsc + " " + __("avoid") + " " + row.node + " (" + row.score + ")";
            } else {
                return rsc + " " + __("prefer") + " " + row.node + " (" + row.score + ")";
            }
            break;

        case 'rsc_colocation':
            if (row.score == "INFINITY") {
                return row.rsc + " " + __("with") + " " + row["with-rsc"];
            } else if (row.score == "-INFINITY") {
                return row.rsc + " " + __("never with") + " " + row["with-rsc"];
            } else if (row.score[0].match(/^-/)) {
                return row.rsc + " " + __("avoid") + " " + row["with-rsc"] + " (" + row.score + ")";
            } else {
                return row.rsc + " " + __("prefer with") + " " + row["with-rsc"] + " (" + row.score + ")";
            }
            break;

        case 'rsc_order':
            return __("First") + " " + row.first + " " + __("then") + " " + row.then + " (" + row.kind + ")";
            break;
        default: return row.type; break;
        }
    };
    
    $('#constraints #middle table.constraints, #states #middle table.constraints')
        .bootstrapTable({
            method: 'get',
            url: Routes.cib_constraints_path(
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
                    field: 'type',
                    title: __('Type'),
                    sortable: true,
                    clickToSelect: true,
                    class: 'col-sm-1',
                    formatter: function(value, row, index) {
                        switch (row.type) {
                        case 'rsc_location': return [
                            '<i class="fa fa-globe text-info" title="',
                            __("Location"),
                            '"></i>'
                        ].join(''); break;
                        case 'rsc_colocation': return [
                            '<i class="fa fa-link text-success" title="',
                            __("Colocation"),
                            '"></i>'
                        ].join(''); break;
                        case 'rsc_order': return [
                            '<i class="fa fa-sort text-warning" title="',
                            __("Order"),
                            '"></i>'
                        ].join(''); break;
                        default: return row.type; break;
                        }
                    }
                },
                {
                    field: 'type',
                    title: __('Name'),
                    sortable: true,
                    switchable: false,
                    clickToSelect: true,
                    formatter: function(value, row, index) {
                        switch (row.type) {
                        case 'rsc_location': return __("Location"); break;
                        case 'rsc_colocation': return __("Colocation"); break;
                        case 'rsc_order': return __("Order"); break;
                        default: return row.type; break;
                        }
                    }
                },
                {
                    field: 'rsc',
                    title: __('Resources'),
                    sortable: true,
                    clickToSelect: true,
                    formatter: function(value, row, index) {
                        return description(row);
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
                            Routes.cib_constraint_path(
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
                }],
        });

    $('#constraints #middle form')
        .validate({
            rules: {
                'node[id]': {
                    minlength: 1,
                    required: true
                }
            }
        });
});
