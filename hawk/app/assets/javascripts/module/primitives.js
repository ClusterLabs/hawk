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
  $('#primitives #middle table.primitives')
    .bootstrapTable({
      method: 'get',
      url: Routes.cib_primitives_path(
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
        title: __('Primitive ID'),
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

            $.ajax({
              dataType: 'json',
              method: 'POST',
              data: {
                _method: 'delete'
              },
              url: Routes.cib_primitive_path(
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
                Routes.edit_cib_primitive_path(
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
                Routes.cib_primitive_path(
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

  $('#primitives #middle form')
    .on('change', '#primitive_template', function(e) {
      var $form = $(e.delegateTarget);
      var $target = $(e.currentTarget);

      if ($target.val()) {
        $option = $target.find('option:selected');

        $form
          .find('[name="primitive[clazz]"]')
            .val($option.data('clazz'))
            .attr('disabled', true)
          .end()
          .find('[name="primitive[provider]"]')
            .val($option.data('provider'))
            .attr('disabled', true)
          .end()
          .find('[name="primitive[type]"]')
            .val($option.data('type'))
            .attr('disabled', true)
          .end();
      } else {
        $form
          .find('[name="primitive[clazz]"]')
            .removeAttr('disabled')
          .end()
          .find('[name="primitive[provider]"]')
            .removeAttr('disabled')
          .end()
          .find('[name="primitive[type]"]')
            .removeAttr('disabled')
          .end();
      }
    })
    .on('change', '#primitive_clazz', function(e) {
      var $form = $(e.delegateTarget);

      var $clazz = $form.find('#primitive_clazz');
      var $provider = $form.find('#primitive_provider');
      var $type = $form.find('#primitive_type');

      $provider
        .find('[data-clazz]')
        .show()
        .not('[data-clazz="' + $clazz.val() + '"]')
        .hide();

      $type
        .find('[data-clazz][data-provider]')
        .show()
        .not('[data-clazz="' + $clazz.val() + '"][data-provider="' + $provider.val() + '"]')
        .hide()
        .end();

      $provider.val('');
      $type.val('');
    })
    .on('change', '#primitive_provider', function(e) {
      var $form = $(e.delegateTarget);

      var $clazz = $form.find('#primitive_clazz');
      var $provider = $form.find('#primitive_provider');
      var $type = $form.find('#primitive_type');

      $provider
        .find('[data-clazz]')
        .show()
        .not('[data-clazz="' + $clazz.val() + '"]')
        .hide();

      $type
        .find('[data-clazz][data-provider]')
        .show()
        .not('[data-clazz="' + $clazz.val() + '"][data-provider="' + $provider.val() + '"]')
        .hide()
        .end();

      $type.val('');
    })
    .find('#primitive_template, #primitive_clazz, #primitive_provider')
      .trigger('change');

  // $('#primitives #middle form')
  //   .validate({
  //     rules: {
  //       'primitive[id]': {
  //         minlength: 1,
  //         required: true
  //       }
  //     }
  //   });
});
