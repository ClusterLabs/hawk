// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
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
    $('.row-offcanvas').toggleClass('active')
  });

  $.growl(
    false,
    {
      element: '#middle .container-fluid',
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

  $.fn.statusCircle = function(status) {
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
    var circle = ['<div class="circle circle-medium ',
                  statusClass(),
                  '">',
                  statusIcon(),
                  '</div>'].join("");
    $(this).html(circle);
  };
});
