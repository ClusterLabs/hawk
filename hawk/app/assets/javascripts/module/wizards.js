// Copyright (c) 2009-2013 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  $('#wizards #middle form')
    .bootstrapWizard({
      tabClass: 'nav nav-pills',
      nextSelector: '.wizard .next',
      previousSelector: '.wizard .previous',
      finishSelector: '.wizard .finish',
      firstSelector: null,
      lastSelector: null,
      onNext: function(tab, nav, index) {
        if ($(nav).parents('form').valid()) {
          return true;
        } else {
          $(nav).parents('form').validate().focusInvalid();
          return false;
        }
      },
      onTabClick: function(tab, nav, index) {
        return false;
      }
    })
    .validate({
      ignore: ":hidden"
    });
});
