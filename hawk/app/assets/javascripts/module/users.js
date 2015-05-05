//======================================================================
//                        HA Web Konsole (Hawk)
// --------------------------------------------------------------------
//            A web-based GUI for managing and monitoring the
//          Pacemaker High-Availability cluster resource manager
//
// Copyright (c) 2009-2013 SUSE LLC, All Rights Reserved.
//
// Author: Tim Serong <tserong@suse.com>
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of version 2 of the GNU General Public License as
// published by the Free Software Foundation.
//
// This program is distributed in the hope that it would be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//
// Further, this software is distributed without any warranty that it is
// free of the rightful claim of any third person regarding infringement
// or the like.  Any license provided herein, whether implied or
// otherwise, applies only to this software file.  Patent licenses, if
// any, provided herein do not apply to combinations of this program with
// other software, or any other product whatsoever.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write the Free Software Foundation,
// Inc., 59 Temple Place - Suite 330, Boston MA 02111-1307, USA.
//
//======================================================================

$(function() {
  $('#users #middle table.users')
    .bootstrapTable({
      method: 'get',
      url: Routes.cib_users_path(
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
        field: 'id',
        title: __('User ID'),
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

            $.ajax({
              dataType: 'json',
              method: 'POST',
              data: {
                _method: 'delete'
              },
              url: Routes.cib_user_path(
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
        },
        formatter: function(value, row, index) {
          var operations = []

          operations.push([
            '<a href="',
                Routes.edit_cib_user_path(
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
                Routes.cib_user_path(
                  $('body').data('cib'),
                  row.id
                ),
              '" class="delete btn btn-default btn-xs" title="',
              __('Delete'),
            '" data-confirm="' + i18n.translate('Are you sure you wish to delete %s?').fetch(row.id) + '">',
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

  $('#users #content form')
    .find('.select')
      .multiselect({
        disableIfEmpty: true,
        enableFiltering: true,
        buttonWidth: '100%',
        onChange: function(element, checked) {
          $(element.context.form)
            .find('[name="revert"]')
              .show()
              .end()
            .find('a.back')
              .attr('data-confirm', __('Any changes will be lost - do you wish to proceed?'))
              .end();
        }
      }).end()
    .validate({
      rules: {
        'user[id]': {
          minlength: 1,
          required: true
        },
        'user[roles][]': {
          required: true
        }
      }
    });
});
