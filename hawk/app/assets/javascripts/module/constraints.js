// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
    var mapkeys = function(str, args) {
        $.each(args, function(key, val) {
            str = str.replace("%" + key.toUpperCase() + "%", val);
        });
        return str;
    };
    var wraptag = function(tag, s) { return "<" + tag + ">" + s + "</" + tag + ">"; };
    var em = function(s) { return wraptag("em", s); };
    var strong = function (s) { return wraptag("strong", s); };
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
                return mapkeys(__("Locate %RSC% on %NODE%"), {rsc: strong(rsc), node: strong(row.node)});
            } else if (row.score == "-INFINITY") {
                return mapkeys(__("Never locate %RSC% on %NODE%"), {rsc: strong(rsc), node: strong(row.node)});
            } else if (row.score[0].match(/^-/)) {
                return mapkeys(__("Avoid locating %RSC% on %NODE% (score: %SCORE%)"), {rsc: strong(rsc), node: strong(row.node), score: row.score});
            } else {
                return mapkeys(__("Prefer locating %RSC% on %NODE% (score: %SCORE%)"), {rsc: strong(rsc), node: strong(row.node), score: row.score});
            }
            break;

        case 'rsc_colocation':
            if ("children" in row) {
                var sets = [];
                $.each(row.children, function(i, e) {
                    var to = [];
                    if ("children" in e) {
                        $.each(e.children, function(i, e) {
                            to.push(e.id);
                        });
                    }
                    sets.push(to.join(", "));
                });
                var rscs = sets.join(" with ");
                var prefix = "";
                var score = "";
                if (row.score == "INFINITY") {
                    prefix = "Locate ";
                } else if (row.score == "-INFINITY") {
                    prefix = "Never locate ";
                } else if (row.score[0].match(/^-/)) {
                    prefix = "Avoid locating ";
                    score = " (score: " + row.score + ")";
                } else {
                    prefix = "Prefer locating ";
                    score = " (score: " + row.score + ")";
                }
                return prefix + rscs + score;
            } else {
                var rsc = row.rsc;
                var withrsc = row["with-rsc"];
                if (row.score == "INFINITY") {
                    return mapkeys(__("Locate %RSC% with %WITH%"), {rsc: strong(rsc), with: strong(withrsc)});
                } else if (row.score == "-INFINITY") {
                    return mapkeys(__("Never locate %RSC% with %WITH%"), {rsc: strong(rsc), with: strong(withrsc)});
                } else if (row.score[0].match(/^-/)) {
                    return mapkeys(__("Avoid locating %RSC% with %WITH% (score: %SCORE%)"), {rsc: strong(rsc), with: strong(withrsc), score: row.score});
                } else {
                    return mapkeys(__("Prefer locating %RSC% with %WITH% (score: %SCORE%)"), {rsc: strong(rsc), with: strong(withrsc), score: row.score});
                }
            }
            break;

        case 'rsc_order':
            if ("children" in row) {
                var sets = [];
                $.each(row.children, function(i, e) {
                    var to = [];
                    if ("children" in e) {
                        $.each(e.children, function(i, e) {
                            to.push(e.id);
                        });
                    }
                    sets.push(to.join(", "));
                });
                sets.join(", then ");
                return "First " + sets + " (kind: " + row.kind + ")";
            } else {
                return mapkeys(__("First %FIRST%, then %THEN% (kind: %KIND%)"),
                           {
                               first: strong(row.first),
                               then: strong(row.then),
                               kind: row.kind
                           });
            }
            break;
        default: return row.type; break;
        }
    };
    var editpath = function(row) {
        switch (row.type) {
        case 'rsc_location': return Routes.edit_cib_location_path($('body').data('cib'), row.id); break;
        case 'rsc_colocation': return Routes.edit_cib_colocation_path($('body').data('cib'), row.id); break;
        case 'rsc_order': return Routes.edit_cib_order_path($('body').data('cib'), row.id); break;
        default: return Routes.edit_cib_location_path($('body').data('cib'), row.id); break;
        };
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
                    field: 'id',
                    title: __('Name'),
                    sortable: true,
                    switchable: false,
                    clickToSelect: true
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
                            editpath(row),
                            '" class="details btn btn-default btn-xs" title="',
                            __('Edit'),
                            '">',
                            '<i class="fa fa-pencil"></i>',
                            '</a> '
                        ].join(''));

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
