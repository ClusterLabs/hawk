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

  function MonitorCheck(el, options) {
    this.$el = $(el);

    this.currentEpoch = this.$el.data('monitor');
    this.currentInterval = null;
    this.currentRefresh = null;

    this.defaults = {
      faster: 15,
      refresh: 90,
      timeout: 90,
      cashe: false
    };

    this.options = $.extend(
      this.defaults,
      options
    );

    this.init();
  }

  MonitorCheck.prototype.init = function() {
    var self = this;

    if (self.$el.data('cib') === 'live') {
      self.processCheck();
      self.updateInterval(self.options.refresh);
    }
  };

  MonitorCheck.prototype.processCheck = function() {
    var self = this;

    $.ajax({
      url: Routes.monitor_path(),
      type: 'GET',

      data: self.currentEpoch,
      cache: self.options.cache,
      timeout: self.options.timeout,

      success: function(data) {
        if (data) {
          if (self.invalidEpoch(data.epoch)) {
            $('body').trigger($.Event('updated.hawk.monitor'));
          } else {
            $('body').trigger($.Event('checked.hawk.monitor'));
          }

          self.updateInterval(self.options.refresh);
        } else {
          $.growl(
            __('Connection to server aborted - will retry every 15 seconds.'),
            { type: 'warning' }
          );

          $('body').trigger($.Event('aborted.hawk.monitor'));
          self.updateInterval(self.options.faster);
        }
      },

      error: function(request) {
        if (request.readyState > 1) {
          if (request.status >= 10000) {
            $.growl(
              __('Connection to server failed - will retry every 15 seconds.'),
              { type: 'danger' }
            );
          } else {
            // $.growl(
            //   request.statusText,
            //   { type: 'danger' }
            // );
          }
        } else {
          $.growl(
            __('Connection to server timed out - will retry every 15 seconds.'),
            { type: 'danger' }
          );
        }

        $('body').trigger($.Event('unavailable.hawk.monitor'));
        self.updateInterval(self.options.faster);
      }
    });
  };

  MonitorCheck.prototype.updateInterval = function(secs) {
    var self = this;

    if (self.currentRefresh !== secs) {
      clearInterval(
        self.currentInterval
      );

      self.currentInterval = win.setInterval(
        function() {
          self.processCheck();
        },
        secs * 1000
      );

      self.currentRefresh = secs;
    }
  };

  MonitorCheck.prototype.invalidEpoch = function(epoch) {
    var self = this;

    if (self.currentEpoch !== epoch) {
      self.currentEpoch = epoch;
      return true;
    } else {
      return false;
    }
  };

  $.fn.monitorCheck = function(options) {
    return this.each(function() {
      new MonitorCheck(this, options);
    });
  };
}(jQuery, document, window));

$(function() {
  $('[data-monitor]').monitorCheck();

  $('body').on('checked.hawk.monitor', function() { console.log('checked'); });
  $('body').on('updated.hawk.monitor', function() { console.log('updated'); });
  $('body').on('unavailable.hawk.monitor', function() { console.log('unavailable'); });
  $('body').on('aborted.hawk.monitor', function() { console.log('aborted'); });
});
