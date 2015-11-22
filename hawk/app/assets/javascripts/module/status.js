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
        metadata: '.metadata',
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

    $.views.converters({
      statusbuttonclass: function(value) {
        if (value == "ok") {
          return "btn btn-success";
        } else if (value == "errors") {
          return "btn btn-danger";
        } else if (value == "maintenance") {
          return "btn btn-info";
        } else {
          return "btn btn-warning";
        }
      },
      statusbuttonicon: function(value) {
        if (value == "ok") {
          return 'fa fa-fw fa-check';
        } else if (value == "errors") {
          return 'fa fa-fw fa-exclamation-triangle';
        } else if (value == "maintenance") {
          return 'fa fa-fw fa-wrench';
        } else if (value == "nostonith") {
          return 'fa fa-fw fa-plug';
        } else {
          return 'fa fa-fw fa-question';
        }
      }
    });

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
          $('#middle .circle').statusCircleFromCIB(cib);
          $(self.options.targets.metadata).link(true, cib);
          $(self.options.targets.content).link(true, cib);

          $(['#states #middle table.resources',
             '#resources #middle table.resources',
             '#states #middle table.tickets',
             '#tickets #middle table.tickets',
             '#nodes #middle table.nodes',
             '#states #middle table.nodes'].join(', '))
            .bootstrapTable('refresh');
        }
      },

      error: function(request) {
        var msg = __('Connection to server failed - will retry every 15 seconds.');
        $.growl(
          msg,
          { type: 'danger' }
        );
        $('#middle .circle').statusCircle('errors', msg);
      }
    });
  };

  $.fn.statusCheck = function(options) {
    return this.each(function() {
      new StatusCheck(this, options);
    });
  };

  $.fn.statusCircleFromCIB = function(cib) {
    if (cib === undefined) {
      cib = $('body').data('content');
    }
    if (cib) {
      var msg = undefined;
      if (cib.errors.length > 0) {
        msg = cib.errors[0].msg;
      }
      $(this).statusCircle(cib.meta.status, msg);
    }
  };
}(jQuery, document, window));

$(function() {
  $('body').statusCheck();
  $('#middle .circle').statusCircleFromCIB();
});
