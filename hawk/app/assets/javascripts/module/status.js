// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

;(function($, doc, win) {
  'use strict';

  function StatusCheck(el, options) {
    this.$el = $(el);

    this.defaults = {
      content: this.$el.data('content'),
      timeout: 90,
      cache: false,
      events: [
        'updated.hawk.monitor'
      ],
      targets: {
        events: el,
        metadata: 'footer .metadata',
        content: '#states #middle'
      },
      templates: {
        error: '#statusError'
      }
    };

    this.options = $.extend(
      this.defaults,
      options
    );

    $.templates({
      statusError: {
        markup: this.options.templates.error
      }
    });

    this.init();
  }

  StatusCheck.prototype.init = function() {
    var self = this;

    $.each(self.options.events, function(i, e) {
      $(self.options.targets.events).on(e, function() {
        self.update();
      });
    });

    $(self.options.targets.metadata).link(
      true,
      self.options.content
    );

    $(self.options.targets.content).link(
      true,
      self.options.content
    );
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

      success: function(resp) {
        if (resp) {
          $(self.options.targets.metadata).link(
            true,
            resp
          );

          $(self.options.targets.content).link(
            true,
            resp
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
