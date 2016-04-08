// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  jQuery.validator.addMethod("wizard_check", function(value, element) {
    if (!this.optional(element)) {
      if ($(element).data('param-type') == 'resource') {
        return /^[^ ]+$/.test(value);
      }
    }
    return true;
  }, __("Must be a valid resource ID"));

  $('#wizards #middle form')
    .bootstrapWizard({
      tabClass: 'nav nav-pills',
      nextSelector: '.wizard .next',
      previousSelector: '.wizard .previous',
      finishSelector: '.wizard .finish',
      firstSelector: null,
      lastSelector: null,
      onNext: function(tab, nav, index) {
        // Disable validation for all fields that are part
        // of a non-required step
        $("[data-depends]").each(function() {
          var depelem = document.getElementById($(this).attr('data-depends'));
          if ($(depelem).val() != "true") {
            $(this).rules("remove", "required");
            $(this).removeAttr("required");
          } else {
            $(this).rules("add", "required");
          }
        });
        if ($(nav).parents('form').valid()) {
          return true;
        } else {
          $(nav).parents('form').validate({
            ignore: ".ignore, :hidden"
          }).focusInvalid();
          return false;
        }
      },
      onTabClick: function(tab, nav, index) {
        return false;
      }
    })
    .validate({
      ignore: ".ignore, :hidden"
    });
  $('#wizards #middle form input').addClass('wizard_check');
  $("[data-wizard-enable]").change(function() {
    $('.form-group').each(function () { $(this).removeClass('has-success'); });
    $('.form-group').each(function () { $(this).removeClass('has-error'); });
    $('.form-group').each(function () { $(this).removeClass('has-feedback'); });
    $('.form-control-feedback').each(function () { $(this).remove(); });
  });

  var verify = $(".wizard-verify");
  var vform = verify.find("form");

  vform.validate();
  vform.submit(function() {
    if (!vform.valid()) {
      vform.validate().focusInvalid();
      return false;
    }

    vform.find(".actions .list-group-item").addClass("disabled");
    vform.find(".notifications").html('<div class="alert alert-info"><i class="fa fa-refresh fa-pulse-opacity fa-2x"></i> ' + __("Applying configuration changes...") + '</div>');
    vform.find(".submit").prop("disabled", true);
  });
  vform.on("ajax:success", function(e, data, status, xhr) {
    vform.find(".actions .list-group-item").removeClass("disabled").addClass("list-group-item-success");
    vform.find(".notifications").html('<div class="alert alert-success">' + __("Changes applied successfully.") + '</div>');
  });
  vform.on("ajax:error", function(e, xhr, status, error) {
    vform.find(".actions .list-group-item:first").removeClass("disabled").addClass("list-group-item-danger");
    var errors = $.map(xhr.responseJSON, function(e) { return '<pre class="bg-danger">' + e + '</pre>'; }).join("");
    vform.find(".notifications").html(errors);
  });
  vform.on("change", "#rootpw", function() {
      vform.find(".submit").prop("disabled", false);
  });

  $('.hljs').each(function(i, block) {
    hljs.highlightBlock(block);
  });
});
