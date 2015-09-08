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
});
