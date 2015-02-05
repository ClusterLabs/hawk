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
  $('#content form')
    .on('keyup', 'input, select', function(e) {
      $(e.delegateTarget)
        .find('[name="revert"]')
          .show()
          .end()
        .find('a.back')
          .attr('data-confirm', __('Any changes will be lost - do you wish to proceed?'))
          .end();
    })
    .on('focus', '.form-group.has-error .form-control', function(e) {
      var error = $(this)
        .siblings('span.error-block')
        .html();

      $(this)
        .siblings('i.fa')
        .tooltip({ title: error })
        .tooltip('show');
    })
    .on('blur', '.form-group.has-error .form-control', function(e) {
      $(this)
        .siblings('i.fa')
        .tooltip('hide');
    })
    .on('keyup', '.form-group.has-error .form-control', function(e) {
      $(this)
        .siblings('i.fa')
        .tooltip('hide');
    });

  $.validator.setDefaults({
    errorElement: 'span',
    errorClass: 'help-block error-block',

    ignore: ':hidden:not(.select)',

    highlight: function(element, errorClass, validClass) {
      if (element.type === "radio") {
        this.findByName(element.name).addClass(errorClass).removeClass(validClass);
      } else {
        $(element)
          .closest('.form-group')
            .removeClass('has-success has-feedback')
            .addClass('has-error has-feedback')
            .find('i.fa')
            .remove()
            .end();

        $(element)
          .after('<i class="fa fa-exclamation fa-lg form-control-feedback"></i>');
      }
    },
    unhighlight: function(element, errorClass, validClass) {
      if (element.type === "radio") {
        this.findByName(element.name).removeClass(errorClass).addClass(validClass);
      } else {
        $(element)
          .closest('.form-group')
            .removeClass('has-error has-feedback')
            .addClass('has-success has-feedback')
            .find('i.fa')
            .remove()
            .end();

        $(element)
          .after('<i class="fa fa-check fa-lg form-control-feedback"></i>');
      }
    },
    errorPlacement: function(error, element) {
      if (element.parent('.input-group').length || element.prop('type') === 'checkbox' || element.prop('type') === 'radio') {
        error
          .insertAfter(element.parent());
      } else {
        error
          .addClass('sr-only')
          .insertAfter(element);
      }
    }
  });
});
