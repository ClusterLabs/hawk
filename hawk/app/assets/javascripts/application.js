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

//= require_tree ./locale
//= require gettext/all

//= require_self

$(function() {
  $('#users #content form')
    .find('[name="user[roles][]"]')
      .multiselect({
        disableIfEmpty: true,
        enableFiltering: true,
        buttonWidth: '100%',
        onChange: function(element, checked) {
          $(element.context.form).bootstrapValidator(
            'revalidateField',
            'user[roles][]'
          );
        }
      })
      .end()
    .on('init.form.bv', function(e, data) {
      $(e.currentTarget).find('[name="revert"]').hide();
    })
    .bootstrapValidator({
      container: 'tooltip',
      live: 'enabled',

      excluded: ':disabled',
      submitButtons: 'input[name="submit"]',

      feedbackIcons: {
        valid: 'fa fa-check',
        invalid: 'fa fa-times',
        validating: 'fa fa-refresh'
      },

      fields: {
        'user[id]': {
          message: 'The ID is not valid',
          validators: {
            notEmpty: {
              message: 'The ID is required'
            }
          }
        },
        'user[roles][]': {
          message: 'The roles are not valid',
          validators: {
            notEmpty: {
              message: 'The roles are required'
            }
          }
        }
      }
    })
    .on('success.field.bv', function(e, data) {
      $(e.currentTarget)
        .find('[name="revert"]').end()
        .find('a.back').attr('data-confirm', __('Any changes will be lost - do you wish to proceed?'));

      return true;
    })
    .on('error.field.bv', function(e, data) {
      $(e.currentTarget)
        .find('[name="revert"]').end()
        .find('a.back').attr('data-confirm', __('Any changes will be lost - do you wish to proceed?'));

      return true;
    });
});
