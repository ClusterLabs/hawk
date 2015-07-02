// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  $('body').on('hidden.bs.modal', '.modal', function() {
    $(this)
      .removeData('bs.modal')
      .find('.modal-content')
      .empty();
  });
});
