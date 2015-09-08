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
            var to = [];
            $.each(e.children, function(i, e) {
              to.push(e.id);
            });
            rscs.push(to.join(", "));
          }
        });
        rsc = rscs.join(' <i class="fa fa-long-arrow-right"></i> ');
      } else {
        rsc = row.rsc;
      }

      var tpl = "%RSC% &nbsp; %PLUS% &nbsp; %NODE%";
      var combiner = ' <i class="fa fa-arrow-right"></i> ';

      if (row.score == "INFINITY") {
      } else if (row.score == "-INFINITY") {
          combiner = ' <i class="fa fa-ban text-danger"></i> ';
      } else if (row.score[0].match(/^-/)) {
          combiner = ' <i class="fa fa-thumbs-o-down fa-fw text-danger"></i> ';
      } else {
          combiner = ' <i class="fa fa-thumbs-o-up fa-fw text-success"></i> ';
      }
      return mapkeys(tpl, {rsc: strong(rsc), node: strong(row.node), plus: combiner});
      break;

    case 'rsc_colocation':
      var rsc = '';
      var tpl = '';
      var combiner = '';
      var withrsc = '';
      if ("children" in row) {
        var sets = [];
        $.each(row.children, function(i, e) {
          if ("children" in e) {
            var to = [];
            $.each(e.children, function(i, e) {
              to.push(e.id);
            });
            sets.push(to.join(", "));
          }
        });
        rsc = sets.join(' <i class="fa fa-long-arrow-right"></i> ');
        tpl = "%PLUS% &nbsp; %RSC%";
        combiner = '<i class="fa fa-plus fa-fw text-success"></i> ';
        if (row.score == "INFINITY") {
        } else if (row.score == "-INFINITY") {
          combiner = '<i class="fa fa-ban text-danger"></i> ';
        } else if (row.score[0].match(/^-/)) {
          combiner = '<i class="fa fa-thumbs-o-down fa-fw text-danger"></i> ';
        } else {
          combiner = '<i class="fa fa-thumbs-o-up fa-fw text-success"></i> ';
        }
      } else {
        rsc = row.rsc;
        withrsc = row["with-rsc"];
        tpl = "%RSC% &nbsp; %PLUS% &nbsp; %WITH%";
        combiner = ' <i class="fa fa-plus fa-fw text-success"></i> ';
        if (row.score == "INFINITY") {
        } else if (row.score == "-INFINITY") {
          combiner = ' <i class="fa fa-ban text-danger"></i> ';
        } else if (row.score[0].match(/^-/)) {
          combiner = ' <i class="fa fa-thumbs-o-down fa-fw text-danger"></i> ';
        } else {
          combiner = ' <i class="fa fa-thumbs-o-up fa-fw text-success"></i> ';
        }
      }
      return mapkeys(tpl, {rsc: strong(rsc), with: strong(withrsc), plus: combiner});

      break;

    case 'rsc_order':
      if ("children" in row) {
        var sets = [];
        $.each(row.children, function(i, e) {
          if ("children" in e) {
            var to = [];
            $.each(e.children, function(i, e) {
              to.push(e.id);
            });
            sets.push(to.join(", "));
          }
        });
        sets.join(" <i class=\"fa fa-long-arrow-right\"></i> ");
        return sets;
      } else {
        return mapkeys("%FIRST% &nbsp; <i class=\"fa fa-long-arrow-right\"></i> &nbsp; %THEN%",
                       {
                         first: strong(row.first),
                         then: strong(row.then)
                       });
      }
      break;
    case 'rsc_ticket':
      if ("children" in row) {
        var sets = [];
        $.each(row.children, function(i, e) {
          if ("children" in e) {
            var to = [];
            $.each(e.children, function(i, e) {
              to.push(e.id);
            });
            sets.push(to.join(", "));
          }
        });
        sets.join(" <i class=\"fa fa-long-arrow-right\"></i> ");
        return mapkeys("%TICKET%: %RSC%",
                       {
                         ticket: strong(row.ticket),
                         rsc: strong(sets)
                       });
      } else {
        return mapkeys("%TICKET%: %RSC%",
                       {
                         ticket: strong(row.ticket),
                         rsc: strong(row.rsc)
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
    case 'rsc_ticket': return Routes.edit_cib_ticket_path($('body').data('cib'), row.id); break;
    default: return Routes.edit_cib_location_path($('body').data('cib'), row.id); break;
    };
  };

  $('#states #middle table.constraints')
    .bootstrapTable({
      method: 'get',
      url: Routes.status_cib_constraints_path(
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
            case 'rsc_ticket': return [
              '<i class="fa fa-ticket text-default" title="',
              __("Ticket"),
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
          field: 'score',
          title: __('Score / Kind'),
          sortable: false,
          clickToSelect: true,
          formatter: function(value, row, index) {
            if ("kind" in row) {
              return row.kind;
            } else  if ("score" in row) {
              return row.score;
            } else {
              return "-";
            }
          }
        },
        {
          field: 'rsc',
          title: __('Resources'),
          sortable: false,
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





  $('#constraints #middle table.constraints')
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
      columns: [{
        field: 'object_type',
        title: __('Type'),
        sortable: true,
        clickToSelect: true,
        class: 'col-sm-2',
        formatter: function(value, row, index) {
          switch(row.object_type) {
            case "location":
              return __("Location");
              break;
            case "colocation":
              return __("Colocation");
              break;
            case "order":
              return __("Order");
              break;
            case "ticket":
              return __("Ticket");
              break;
            default:
              return row.object_type;
              break;
          }
        }
      }, {
        field: 'id',
        title: __('Constraint'),
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

            if (confirm(i18n.translate('Are you sure you wish to delete %s?').fetch(row.id))) {
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
            case "location":
              var editRoute = Routes.edit_cib_location_path(
                $('body').data('cib'),
                row.id
              );

              var deleteRoute = Routes.cib_location_path(
                $('body').data('cib'),
                row.id
              );

              break;
            case "colocation":
              var editRoute = Routes.edit_cib_colocation_path(
                $('body').data('cib'),
                row.id
              );

              var deleteRoute = Routes.cib_colocation_path(
                $('body').data('cib'),
                row.id
              );

              break;
            case "order":
              var editRoute = Routes.edit_cib_order_path(
                $('body').data('cib'),
                row.id
              );

              var deleteRoute = Routes.cib_order_path(
                $('body').data('cib'),
                row.id
              );

              break;
            case "ticket":
              var editRoute = Routes.edit_cib_ticket_path(
                $('body').data('cib'),
                row.id
              );

              var deleteRoute = Routes.cib_ticket_path(
                $('body').data('cib'),
                row.id
              );

              break;
            default:
              var editRoute = Routes.edit_cib_constraint_path(
                $('body').data('cib'),
                row.id
              );

              var deleteRoute = Routes.cib_constraint_path(
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
