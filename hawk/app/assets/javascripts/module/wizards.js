// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
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
    $("[data-wizard-enable]").change(function() {
        $('.form-group').each(function () { $(this).removeClass('has-success'); });
        $('.form-group').each(function () { $(this).removeClass('has-error'); });
        $('.form-group').each(function () { $(this).removeClass('has-feedback'); });
        $('.form-control-feedback').each(function () { $(this).remove(); });
    });
});
