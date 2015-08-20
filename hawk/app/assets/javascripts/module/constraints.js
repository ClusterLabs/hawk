// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
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
      columns: [{
        field: 'type',
        title: __('Constraint'),
        sortable: true,
        switchable: false,
          clickToSelect: true,
          formatter: function(value, row, index) {
              switch (row.type) {
              case 'rsc_location': return __("Location"); break;
              case 'rsc_colocation': return __("Co-location"); break;
              case 'rsc_order': return __("Order"); break;
              default: return row.type; break;
              }
          }
      },
                {
                    field: 'score',
                    title: __('Score'),
                    sortable: true,
                    switchable: false,
                    clickToSelect: true,
                },
                {
                    field: 'rsc',
                    title: __('A'),
                    sortable: true,
                    switchable: false,
                    clickToSelect: true,
                },
                {
                    field: 'with-rsc',
                    title: __('B'),
                    sortable: true,
                    switchable: false,
                    clickToSelect: true,
                },
                {
                    field: 'node',
                    title: __('Node'),
                    sortable: true,
                    switchable: false,
                    clickToSelect: true,
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
