// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  window.userIsNavigatingAway = false;
  var _obunload = (window.onbeforeunload) ? window.onbeforeunload : function() {};
  window.onbeforeunload = function() {
     _obunload.call( window );
     window.userIsNavigatingAway = true;
  };

  $.validator.addMethod("resource-id", function(value, element) {
    return this.optional(element) || /^[a-zA-Z_-][a-zA-Z0-9_-]*$/i.test(value);
  }, __("Invalid ID"));

  $('[data-toggle="tooltip"]').tooltip();
  $('[data-toggle="popover"]').popover();
  $('.nav-tabs').stickyTabs();

  $('ul.list-group.sortable').sortable({
    forcePlaceholderSize: true,
    handle: 'i.fa-bars',
    items: ':not(.disabled)',
    placeholderClass: 'sortable-placeholder list-group-item'
  });

  $('.navbar a.toggle').click(function () {
    $('.nav-wrapper').toggleClass('active')
  });

  $.growl(
    false,
    {
      element: '#middle #flashes',
      mouse_over: 'pause',
      allow_dismiss: true
    }
  );

  $.blockUI.defaults.css.padding = '20px';

  $.fn.toggleify = function() {
    this.find('span.toggleable').on('click', function (e) {
      if ($(this).hasClass('collapsed')) {
        $(this)
          .removeClass('collapsed')
          .parents('fieldset')
          .find('.content')
          .slideDown();
        $(this)
          .find('i')
          .removeClass('fa-chevron-down')
          .addClass('fa-chevron-up');
      } else {
        $(this)
          .addClass('collapsed')
          .parents('fieldset')
          .find('.content')
          .slideUp();
        $(this)
          .find('i')
          .removeClass('fa-chevron-up')
          .addClass('fa-chevron-down');
      }
    })
  };

  $.fn.statusCircle = function(status, tooltip) {
    if (tooltip === undefined) {
      if (status == "ok") {
        tooltip = __("OK");
      } else if (status == "maintenance") {
        tooltip = __("Maintenance mode");
      } else if (status == "errors") {
        tooltip = __("An error has occurred");
      } else {
        tooltip = status;
      }
    }
    var statusClass = function() {
      if (status == "ok") {
        return "circle-success";
      } else if (status == "errors") {
        return "circle-danger";
      } else if (status == "maintenance") {
        return "circle-info";
      } else {
        return "circle-warning";
      }
    };

    var statusIcon = function() {
      if (status == "ok") {
        return '<i class="fa fa-check text"></i>';
      } else if (status == "errors") {
        return '<i class="fa fa-exclamation-triangle text"></i>';
      } else if (status == "maintenance") {
        return '<i class="fa fa-wrench text"></i>';
      } else if (status == "nostonith") {
        return '<i class="fa fa-plug text"></i>';
      } else {
        return '<i class="fa fa-question text"></i>';
      }
    };
    var unquote = function(str) {
      return str.replace(/["']/g, "");
    };
    var sizeclass = "";
    if ($(this).hasClass('circle-large')) {
      sizeclass = 'circle-large ';
    } else if ($(this).hasClass('circle-medium')) {
      sizeclass = 'circle-medium ';
    } else if ($(this).hasClass('circle-medium')) {
      sizeclass = 'circle-small ';
    }
    var circle = ['<div class="circle ', sizeclass,
                  statusClass(),
                  '" data-toggle="tooltip" data-placement="bottom" data-html="true" title="',
                  unquote(tooltip),
                  '">',
                  statusIcon(),
                  '</div>'].join("");
    var parent = $(this).parent();
    $(this).replaceWith(circle);
    parent.find('[data-toggle=tooltip]').tooltip();
  };

  $.rails.allowAction = function(link) {
    if (!link.attr('data-confirm')) {
      return true;
    }
    $.rails.showConfirmDialog(link);
    return false;
  };

  $.rails.confirmed = function(link) {
    link.removeAttr('data-confirm');
    link.trigger('click.rails');
  };

  $.hawkAsyncConfirm = function(message, on_ok) {
    if (!message) {
      message = _('Continue?');
    }
    var html = [
      '<div class="modal fade" id="confirmationDialog" role="dialog" tabindex="-1" aria-hidden="true">',
      '<div class="modal-dialog">',
      '<div class="modal-content">',
      '<form class="form-horizontal" role="form" onsubmit="return false;">',
      '<div class="modal-header">',
      '<button class="close" type="button" data-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only">', __('Close'), '</span></button>',
      '<div class="text-center">',
      '<i class="fa fa-5x fa-exclamation-triangle text-warning"></i>',
      '</div>',
      '</div>',
      '<div class="modal-body">',
      '<div class="center-block">',
      '<h4 class="text-center">', message, '</h4>',
      '</div>',
      '</div>',
      '<div class="modal-footer">',
      '<button class="btn btn-default cancel" data-dismiss="modal">', __('Cancel'),'</button>',
      '<button class="btn btn-danger commit" data-dismiss="modal">', __('OK'),'</button>',
      '</div>',
      '</form>',
      '</div>',
      '</div>',
      '</div>'
    ];
    var modal = $(html.join(''));
    modal.css('z-index', 100000);
    modal.find('.commit').on('click', function() {
      on_ok();
      $('#confirmationDialog').modal('hide');
      return true;
    });

    modal.on('hidden.bs.modal', function () {
      modal.remove();
    });

    $('body').append(modal);
    modal.modal();
  };

  $.rails.showConfirmDialog = function(link) {
    $.hawkAsyncConfirm(link.attr('data-confirm'), function() {
      $.rails.confirmed(link);
    });
  };

  $.views.converters("hasKeys", function(val) {
    return !($.isEmptyObject(val));
  });
});
