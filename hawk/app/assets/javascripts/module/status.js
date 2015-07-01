// Copyright (c) 2009-2013 Tim Serong <tserong@suse.com>
// See COPYING for license.

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
