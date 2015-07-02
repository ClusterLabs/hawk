// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

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
      cache: false
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
      timeout: self.options.timeout * 1000,

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

  // $('body').on('checked.hawk.monitor', function() { console.log('checked'); });
  // $('body').on('updated.hawk.monitor', function() { console.log('updated'); });
  // $('body').on('unavailable.hawk.monitor', function() { console.log('unavailable'); });
  // $('body').on('aborted.hawk.monitor', function() { console.log('aborted'); });
});
