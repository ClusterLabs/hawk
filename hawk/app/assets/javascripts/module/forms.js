// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  $('form fieldset span.toggleable').on('click', function (e) {
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
  });

  $('#middle form')
    .on('keyup', 'input, select', function(e) {
      $(e.delegateTarget)
        .find('[name="revert"]')
          .show()
          .end()
        .find('a.back')
          .attr('data-confirm', __('Any changes will be lost - do you wish to proceed?'))
          .end();
    })
    .on('focus', '.form-group.has-error .form-control', function(e) {
      var error = $(this)
        .siblings('span.error-block')
        .html();

      $(this)
        .siblings('i.fa.form-control-feedback')
        .tooltip({ title: error })
        .tooltip('show');
    })
    .on('blur', '.form-group.has-error .form-control', function(e) {
      $(this)
        .siblings('i.fa.form-control-feedback')
        .tooltip('hide');
    })
    .on('keyup', '.form-group.has-error .form-control', function(e) {
      $(this)
        .siblings('i.fa.form-control-feedback')
        .tooltip('hide');
    });

  $.validator.setDefaults({
    errorElement: 'span',
    errorClass: 'help-block error-block',

    ignore: ':hidden:not(.select)',

    highlight: function(element, errorClass, validClass) {
      if (element.type === "radio") {
        this.findByName(element.name).addClass(errorClass).removeClass(validClass);
      } else {
        $(element)
          .closest('.form-group')
            .removeClass('has-success has-feedback')
            .addClass('has-error has-feedback')
            .find('i.fa.form-control-feedback')
            .remove()
            .end();

        $(element)
          .after('<i class="fa fa-exclamation fa-lg form-control-feedback"></i>');
      }
    },
    unhighlight: function(element, errorClass, validClass) {
      if (element.type === "radio") {
        this.findByName(element.name).removeClass(errorClass).addClass(validClass);
      } else {
        $(element)
          .closest('.form-group')
            .removeClass('has-error has-feedback')
            .addClass('has-success has-feedback')
            .find('i.fa.form-control-feedback')
            .remove()
            .end();

        $(element)
          .after('<i class="fa fa-check fa-lg form-control-feedback"></i>');
      }
    },
    errorPlacement: function(error, element) {
      if (element.parent('.input-group').length || element.prop('type') === 'checkbox' || element.prop('type') === 'radio') {
        error
          .insertAfter(element.parent());
      } else {
        error
          .addClass('sr-only')
          .insertAfter(element);
      }
    }
  });
});
