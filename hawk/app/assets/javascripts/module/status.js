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
      dataType: 'json',
      cache: self.options.cache,
      timeout: self.options.timeout * 1000,

      success: function(cib) {
        if (cib) {
          $('body').data('content', cib);
          $('#middle .circle').statusCircle(cib.meta.status);
          $(self.options.targets.metadata).link(true, cib);
          $(self.options.targets.content).link(true, cib);
        }
      },

      error: function(request) {
        $.growl(
          __('Connection to server failed - will retry every 15 seconds.'),
          { type: 'danger' }
        );
        $('#middle .circle').statusCircle('errors');
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
