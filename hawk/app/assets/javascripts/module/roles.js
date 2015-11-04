// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  $('#roles #middle table.roles')
    .bootstrapTable({
      method: 'get',
      url: Routes.cib_roles_path(
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
        field: 'id',
        title: __('Role ID'),
        sortable: true,
        switchable: false,
        clickToSelect: true
      }, {
        field: 'operate',
        title: __('Operations'),
        sortable: false,
        clickToSelect: false,
        class: 'col-sm-1',
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
                url: Routes.cib_role_path(
                  $('body').data('cib'),
                  row.id,
                  { format: 'json' }
                ),

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
          var operations = []

          operations.push([
            '<a href="',
                Routes.edit_cib_role_path(
                  $('body').data('cib'),
                  row.id
                ),
              '" class="edit btn btn-default btn-xs" title="',
              __('Edit'),
            '">',
              '<i class="fa fa-pencil"></i>',
            '</a> '
          ].join(''));

          operations.push([
            '<a href="',
                Routes.cib_role_path(
                  $('body').data('cib'),
                  row.id
                ),
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

  $('#roles #middle form')
    // .find('.select')
    //   .multiselect({
    //     disableIfEmpty: true,
    //     enableFiltering: true,
    //     buttonWidth: '100%'
    //   }).end()
    .on('click', '.rule.add', function(e) {
      e.preventDefault();

      var current = $(e.currentTarget)
        .closest('fieldset');

      current
        .clone()
        .find('input, select')
          .val('')
          .end()
        .find('.form-group')
          .removeClass('has-feedback')
          .removeClass('has-error')
          .end()
        .insertAfter(current);
    })
    .on('click', '.rule.remove', function(e) {
      e.preventDefault();

      $(e.currentTarget)
        .closest('fieldset')
        .fadeOut()
        .remove();
    })
    .on('click', '.rule.up', function(e) {
      e.preventDefault();

      var current = $(e.currentTarget)
        .closest('fieldset');

      current.insertBefore(current.prev());
    })
    .on('click', '.rule.down', function(e) {
      e.preventDefault();

      var current = $(e.currentTarget)
        .closest('fieldset');

      current.insertAfter(current.next());
    })
    .on('click', '.rule.add, .rule.remove, .rule.up, .rule.down', function(e) {
      e.preventDefault();

      $(e.delegateTarget)
        .find('[name="revert"]')
          .show()
          .end()
        .find('a.back')
          .attr('data-confirm', __('Any changes will be lost - do you wish to proceed?'))
          .end();

      $(e.currentTarget)
        .closest('fieldset')
        .siblings()
        .andSelf()
        .each(function(index, current) {
          $(current)
            .find('.form-control')
            .each(function(i, input) {
              var name = $(input).attr('name');
              var splitted = name.split('][');

              splitted[splitted.length - 2] = index.toString();
              $(input).attr('name', splitted.join(']['));
            });
        });
    })
    .validate({
      rules: {
        'role[id]': {
          minlength: 1,
          required: true
        }
      }
    });
});
