// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  $('[data-help-target]').each(function() {
    $(
      $(this).data('help-target')
    ).hide();
  });

  $(
    document
  ).on('mouseenter', '[data-help-filter]', function() {
    $target = $(
      $(this).parents('[data-help-target]').data('help-target')
    );

    $target
      .hide()
      .filter($(this).data('help-filter'))
      .show();
  }).on('mouseleave', '[data-help-filter]', function() {
    $target = $(
      $(this).parents('[data-help-target]').data('help-target')
    );

    $target
      .hide();
  });
});
