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

  function Status(el, options) {
    this.$el = $(el);

    this.defaults = {
      requestTimeout: 90000,
      requestCache: false,
      currentEpoch: ''
    };

    this.options = $.extend(
      this.defaults,
      options
    );

    this.init();
  }

  Status.prototype.init = function() {
    var self = this;

    if (self.$el.data('cib') === 'live') {
      self.process();

      setInterval(
        self.process,
        90000
      );
    }
  };

  Status.prototype.process = function() {
    var self = this;

    $.ajax({
      url: Routes.monitor_path(),
      type: 'GET',

      data: self.options.currentEpoch,
      cache: self.options.requestCache,
      timeout: self.options.requestTimeout,

      success: function(data) {
        if (data) {
          if (data.epoch != self.options.currentEpoch) {








            // Trigger full update if the epoch has changed, or if it's a geo-cluster;
            // this means geo clusters will get an update every minute or so, which
            // means if it's at all possible for booth status to drift without updating
            // the CIB, at least it will be apparent within a minute or so.
            //update_cib();


            console.log('update cib');










          } else {
            self.process();
          }
        } else {






          console.log('no data');

          // This can occur when onSuccess is called in FF on an
          // aborted request; re-request cib in 15 seconds (see also
          // beforeunload handler in hawk_init).
          /*
          update_errors([GETTEXT.err_conn_aborted()]);
          hide_status();
          */






          setInterval(
            self.process,
            15000
          );
        }
      },

      error: function(request) {







        /*
        if (request.readyState > 1) {
          // Can't rely on request.status if not ready enough
          if (request.status >= 10000) {
            // Crazy winsock(?) error on IE when request aborted
            update_errors([GETTEXT.err_conn_failed()]);
          } else {
            update_errors([GETTEXT.err_unexpected(request.status + " " + request.statusText)]);
          }
        } else {
          // Request timed out
          update_errors([GETTEXT.err_conn_timeout()]);
        }
        hide_status();
        */

        console.log('error');







        setInterval(
          self.process,
          15000
        );
      }
    });

  };

  $.fn.statusCheck = function(options) {
    return this.each(function() {
      new Status(this, options);
    });
  };
}(jQuery, document, window));

$(function() {
  $('body').statusCheck();
});
