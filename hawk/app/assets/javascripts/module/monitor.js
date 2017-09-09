// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

;(function($, doc, win) {
  window.userIsNavigatingAway = false;
  var _obunload = (window.onbeforeunload) ? window.onbeforeunload : function() {};
  window.onbeforeunload = function() {
     _obunload.call( window );
     window.userIsNavigatingAway = false;
  };

  function MonitorCheck(el, options) {
    this.defaults = {
      faster: 15,
      timeout: 90,
      cache: false
    };
    this.options = $.extend(this.defaults, options);
    if ($('body').data('cib') === 'live') {
      this.processCheck();
    }
  }

  MonitorCheck.prototype.processCheck = function() {
    var self = this;

    $('.circle').statusCircleFromCIB();

    $.ajax({
      url: "/monitor.json",
      type: 'GET',
      data: $('body').data('content').meta.epoch,
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
          if (window.userIsNavigatingAway) {
            return;
          }
          var msg = __('Connection to server aborted - will retry every 15 seconds.');
          $.growl(msg, { type: 'warning' });
          $('.circle').statusCircle('disconnected', msg);
          $('body').trigger($.Event('aborted.hawk.monitor'));
          setTimeout(function() { self.processCheck(); }, self.options.faster * 1000);
        }
      },

      error: function(request) {
        if (window.userIsNavigatingAway)
          return;
        var msg = null;
        var code = 'danger';
        var status = 'errors';
        if (request.readyState == 4 && request.status == 200) {
          msg = __('Failed to parse monitor response - Internal server error.');
          code = 'warning';
        } else if (request.readyState > 1) {
          if (request.status >= 10000) {
            msg =  __('Connection to server failed - will retry every 15 seconds.');
          }
        } else {
          msg = __('Connection to server timed out - will retry every 15 seconds.');
          code = 'warning';
          status = 'disconnected';
        }

        if (msg != null) {
          $.growl(msg, { type: 'warning' });
          $('.circle').statusCircle(status, msg);
          $('body').trigger($.Event('unavailable.hawk.monitor'));
        }
        setTimeout(function() { self.processCheck(); }, self.options.faster * 1000);
      }
    });
  };

  MonitorCheck.prototype.updateEpoch = function(epoch) {
    if (epoch !== undefined) {
      var cib = $('body').data('content');
      return !cib || cib.meta.epoch !== epoch;
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
  $('body').monitorCheck();

  $.updateCib = function() {
    $('body').trigger($.Event('updated.hawk.monitor'));
  };

  $.runSimulator = function() {
    if ($('body').data('cib') != "live") {
      $('body').trigger($.Event('hawk.run.simulator'));
    } else {
      $.updateCib();
    }
  };
});
