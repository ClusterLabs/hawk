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
  $('#users #content table.users')
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
      minimumCountColumns: 1,
      columns: [{
        field: 'id',
        title: __('User ID'),
        sortable: true,
        clickToSelect: true
      }, {
        field: 'operate',
        title: __('Operations'),
        sortable: false,
        clickToSelect: false,
        class: 'col-sm-1',
        formatter: function(value, row, index) {
          return [
            '<a class="edit" href="',
              Routes.edit_cib_user_path(
                $('body').data('cib'),
                row.id
              ),
            '">',
              '<i class="fa fa-pencil"></i>',
            '</a> ',
            '<a class="delete" href="',
              Routes.cib_user_path(
                $('body').data('cib'),
                row.id
              ),
            '" data-confirm="',
              i18n.translate('Are you sure you wish to delete %s?').fetch(row.id),
            '" data-method="delete">',
              '<i class="fa fa-trash"></i>',
            '</a>'
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
