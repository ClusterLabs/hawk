// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  $('form fieldset').toggleify();

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
      var group = $(this).closest('.form-group');
      var error = group.find('.form-control-feedback').data('title');
      if (!error) {
        error = group.find('.form-control-feedback').data('original-title');
      }
      if (!error) {
        error = group.find('.error-block').html();
      }

      group.find('.form-control-feedback').tooltip({title: error }).tooltip('show');
    })
    .on('blur', '.form-group.has-error .form-control', function(e) {
      var group = $(this).closest('.form-group');
      group.find('.form-control-feedback').tooltip('hide');
    })
    .on('keyup', '.form-group.has-error .form-control', function(e) {
      var group = $(this).closest('.form-group');
      group.find('.form-control-feedback').tooltip('hide');
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
          .after('<i class="fa fa-lg form-control-feedback"></i>');
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
          .after('<i class="fa fa-lg form-control-feedback"></i>');
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
