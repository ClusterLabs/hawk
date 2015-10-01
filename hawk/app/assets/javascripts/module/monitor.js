// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

;(function($, doc, win) {
  'use strict';

  function MonitorCheck(el, options) {
    this.$el = $(el);

    this.currentEpoch = this.$el.data('epoch');

    this.defaults = {
      faster: 15,
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
    }
  };

  MonitorCheck.prototype.processCheck = function() {
    var self = this;

    $.ajax({
      url: Routes.monitor_path(),

      type: 'GET',
      data: self.currentEpoch,
      dataType: "json",
      cache: self.options.cache,
      timeout: self.options.timeout * 1000,

      success: function(data) {
        if (data) {
          if (self.updateEpoch(data.epoch)) {
            $('body').trigger($.Event('updated.hawk.monitor'));
          } else {
            $('body').trigger($.Event('checked.hawk.monitor'));
          }

          self.processCheck();
        } else {
          $.growl(
            __('Connection to server aborted - will retry every 15 seconds.'),
            { type: 'warning' }
          );

          $('body').trigger($.Event('aborted.hawk.monitor'));

          setTimeout(function() { self.processCheck(); }, self.options.faster * 1000);
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
        setTimeout(function() { self.processCheck(); }, self.options.faster * 1000);
      }
    });
  };

  MonitorCheck.prototype.updateEpoch = function(epoch) {
    if (epoch !== undefined) {
      var changed = this.currentEpoch !== epoch;
      this.currentEpoch = epoch;
      return changed;
    }
    return false;
  };

  $.fn.monitorCheck = function(options) {
    return this.each(function() {
      new MonitorCheck(this, options);
    });
  };
}(jQuery, document, window));

$(function() {
  $('#states').monitorCheck();

  $.updateCib = function() {
    $('body').trigger($.Event('updated.hawk.monitor'));
  };

  $('body').on('updated.hawk.monitor', function() {
    $(['#states #middle table.resources',
       '#resources #middle table.resources',
       '#states #middle table.tickets',
       '#tickets #middle table.tickets',
       '#nodes #middle table.nodes',
       '#states #middle table.nodes'].join(', '))
      .bootstrapTable('refresh');
  });

});
