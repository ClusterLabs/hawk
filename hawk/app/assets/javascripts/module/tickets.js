// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  $('#tickets #middle table.tickets')
    .bootstrapTable({
      method: 'get',
      url: Routes.cib_tickets_path(
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
      showRefresh: false,
      minimumCountColumns: 0,
      sortName: 'id',
      sortOrder: 'asc',
      columns: [{
        field: 'id',
        title: __('ID'),
        sortable: true,
        switchable: false,
        clickToSelect: true
      }, {
        field: 'ticket',
        title: __('Ticket'),
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
          'click .delete': function (e, value, row, index) {
            e.preventDefault();
            if (row.id == null) {
              return false;
            }
            $.hawkDeleteOperation(row.id, Routes.cib_ticket_path($('body').data('cib'), row.id, { format: 'json' }));
            return false;
          }
        },
        formatter: function(value, row, index) {

          if (row.id == null) {
            return "";
          }

          var operations = []

          operations.push([
            '<a href="',
                Routes.edit_cib_ticket_path($('body').data('cib'), row.id),
              '" class="edit btn btn-default btn-xs" title="',
              __('Edit'),
            '">',
              '<i class="fa fa-pencil"></i>',
            '</a> '
          ].join(''));

          operations.push([
            '<a href="',
                Routes.cib_ticket_path($('body').data('cib'), row.id),
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

  $('#cib #middle table.tickets')
    .bootstrapTable({
      ajax: function(params) {
        var cib = $('body').data('content');
        params.success($.map(cib.tickets, function(t) {
          return t;
        }, "success", {}));
        params.complete({}, "success");
      },
      classes: "table table-hover table-striped",
      pagination: false,
      pageSize: 50,
      pageList: [10, 25, 50, 100, 200],
      sidePagination: 'client',
      smartDisplay: false,
      search: false,
      searchAlign: 'left',
      showColumns: false,
      showRefresh: false,
      minimumCountColumns: 0,
      rowStyle: function(row, index) {
        if (row.state == "granted") {
          return { classes: ["success"] };
        } else if (row.state == "elsewhere") {
          return { classes: ["warning"] };
        } else if (row.state == "revoked") {
          return {};
        } else {
          return { classes: ["warning"] };
        }
      },
      sortName: 'id',
      sortOrder: 'asc',
      columns: [{
        field: 'state',
        title: __('Status'),
        sortable: false,
        clickToSelect: false,
        class: 'col-sm-1',
        formatter: function(value, row, index) {
          var ret = [];
          if (row.state == "granted") {
            ret = [
              '<i class="fa fa-check-circle fa-lg text-success" title="',
              __("Granted"),
              '"></i>'
            ];
          } else if (row.state == "elsewhere") {
            ret = [
              '<i class="fa fa-arrow-circle-o-left fa-lg text-info" title="',
              __("Elsewhere"),
              '"></i>'
            ];
          } else {
            ret = [
              '<i class="fa fa-ban fa-lg text-danger" title="',
              __("Revoked"),
              '"></i>'
            ];
          }
          return ret.join('');
        }
      }, {
        field: 'id',
        title: __('Ticket'),
        sortable: false,
        switchable: false,
        clickToSelect: false
      }, {
        field: 'last_granted',
        title: __('Last Granted'),
        sortable: true,
        switchable: false,
        clickToSelect: true
      }, {
        field: 'granted',
        title: __('Granted'),
        align: 'right',
        halign: 'right',
        sortable: false,
        clickToSelect: false,
        class: 'col-sm-1',
        events: {
          'click .grant': function (e, value, row, index) {
            e.preventDefault();
            if (row.id == null) {
              return false;
            }

            $.hawkRunOperation(
              i18n.translate('This will request the ticket %s be granted to the present site. Do you want to continue?').fetch(row.id),
              [$(this).attr('href'), ".json"].join(""));
            return false;
          },
          'click .revoke': function (e, value, row, index) {
            e.preventDefault();
            if (row.id == null) {
              return false;
            }

            $.hawkRunOperation(
              i18n.translate('This will request the ticket %s be revoked. Do you want to continue?').fetch(row.id),
              [$(this).attr('href'), ".json"].join(""));
            return false;
          }
        },
        formatter: function(value, row, index) {
          if (row.id == null) {
            if (!row.granted) {
              return '<a class="btn btn-default btn-xs disabled" disabled><i class="fa fa-toggle-off"></i><a>';
            } else {
              return '<a class="btn btn-default btn-xs disabled" disabled><i class="fa fa-toggle-on text-success"></i><a>';
            }
          }

          if (!row.granted) {
            return [
              '<a href="',
              Routes.grant_cib_tickets_path($('body').data('cib'), row.id),
              '" class="grant btn btn-default btn-xs" title="',
                __('Grant'),
              '">',
                '<i class="fa fa-toggle-off"></i>',
              '</a>'
            ].join('');
          } else {
            return [
              '<a href="',
                Routes.revoke_cib_tickets_path($('body').data('cib'), row.id),
              '" class="revoke btn btn-default btn-xs" title="',
                __('Revoke'),
              '">',
                '<i class="fa fa-toggle-on text-success"></i>',
              '</a>'
            ].join('');
          }
        }
      }, {
        field: 'id',
        title: __('Operations'),
        sortable: false,
        clickToSelect: false,
        class: 'col-sm-2',
        align: 'right',
        halign: 'right',
        events: {
          'click .revoke': function (e, value, row, index) {
            e.preventDefault();
            if (row.id == null) {
              return false;
            }
            $.hawkRunOperation(
              i18n.translate('Revoking ticket %s from this cluster. Do you want to continue?').fetch(row.id),
              [$(this).attr('href'), ".json"].join(""));
            return false;
          }
        },
        formatter: function(value, row, index) {
          if (row.id == null) {
            return "";
          }

          var operations = [];

          if (row.state == "elsewhere" || row.state == "granted") {
            operations.push([
              '<a href="',
              Routes.revoke_cib_tickets_path($('body').data('cib'), row.id),
              '" class="revoke btn btn-default btn-xs" title="',
              __('Revoke'),
              '">',
              '<i class="fa fa-minus"></i>',
              '</a> '
            ].join(''));
          }

          operations.push([
            '<a href="',
            Routes.cib_ticket_path($('body').data('cib'), row.id),
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

  // $('#tickets #middle form')
  //   .validate({
  //     rules: {
  //       'ticket[id]': {
  //         minlength: 1,
  //         required: true
  //       }
  //     }
  //   });
});
