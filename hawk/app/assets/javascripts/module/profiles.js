// Copyright (c) 2009-2013 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  $('#profiles #middle form')
    .find('.select')
      .multiselect({
        disableIfEmpty: true,
        enableFiltering: true,
        buttonWidth: '100%',
        label: function(element) {
          return $(element).html() + ' [' + $(element).val() + ']';
        },
        buttonText: function(element) {
          return $(element).html() + ' [' + $(element).val() + ']';
        },
        onChange: function(element) {
          $(element.context.form)
            .find('[name="revert"]')
              .show()
              .end()
            .find('a.back')
              .attr('data-confirm', __('Any changes will be lost - do you wish to proceed?'))
              .end();
        }
      }).end()
    .validate({
      rules: {
        'profile[language]': {
          required: true
        }
      }
    });
});
