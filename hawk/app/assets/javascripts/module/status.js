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

;(function($, doc, win) {
  'use strict';

  function StatusCheck(el, options) {
    this.$el = $(el);

    this.defaults = {
      timeout: 90,
      cache: false,
      events: [
        'updated.hawk.monitor',
        'checked.hawk.monitor'
      ],
      targets: {
        events: el,
        metadata: 'footer .metadata',
        content: '#dashboards #middle'
      }
    };

    this.options = $.extend(
      this.defaults,
      options
    );

    this.init();
  }

  StatusCheck.prototype.init = function() {
    var self = this;

    $.each(self.options.events, function(i, e) {
      $(self.options.targets.events).on(e, function() {
        self.update();
      });
    });
  };

  StatusCheck.prototype.update = function() {
    var self = this;

    $.ajax({
      url: Routes.cib_path(
        $('body').data('cib'),
        { format: 'json' }
      ),

      type: 'GET',
      cache: self.options.cache,
      timeout: self.options.timeout * 1000,

      success: function(data) {
        if (data) {
          $(self.options.targets.metadata).link(
            true,
            data
          );

          $(self.options.targets.content).link(
            true,
            $.extend(
              {

              },
              data
            )
          );
        }
      },

      error: function(request) {



        console.log('status update failed', arguments);



      }
    });
  };

  $.fn.statusCheck = function(options) {
    return this.each(function() {
      new StatusCheck(this, options);
    });
  };
}(jQuery, document, window));

$(function() {
  $('body').statusCheck();
});
