// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// Copyright (c) 2015-2016 Kristoffer Gronlund <kgronlund@suse.com>
// Copyright (c) 2016 Ayoub Belarbi <abelarbi@suse.com>
// See COPYING for license.

;(function($) {

  window.dashboardSetupAddClusterForm = function() {
    $('#new_cluster').toggleify();
    $('#new_cluster').on("submit", function() {
      $('.modal-content .form-errors').append([
        '<div class="alert alert-info">',
        '<i class="fa fa-refresh fa-2x fa-pulse-opacity"></i> ',
        __("Please wait..."),
        '</div>'
      ].join(''));
      $(this).find('.submit').prop('disabled', true);
      return true; // ensure submit actually happens
    });
    $('#new_cluster').on("ajax:success", function(e, data, status, xhr) {
      $('#modal').modal('hide');
      $('.modal-content').html('');
      // dashboardAddCluster(data);
      location.reload();
      $.growl({ message: __('Cluster added successfully.')}, {type: 'success'});
    }).on("ajax:error", function(e, xhr, status, error) {
      $(e.data).render_form_errors( $.parseJSON(xhr.responseText) );
      $('#new_cluster').find('.submit').prop('disabled', false);
    });

    $.fn.render_form_errors = function(errors){
      this.clear_previous_errors();
      // show error messages in input form-group help-block and highlight the input field
      var text = "";
      var class_name = "";
      $.each(errors, function(field, messages) {
        text += "<div class=\"alert alert-danger\">";
        text += field + ': ' + messages.join(', ');
        text += "</div>";
        class_name = '#cluster_' + field;
        $(class_name).closest('.form-group').addClass('has-error');
      });
      $('form').find('.form-errors').html(text);
    };

    $.fn.clear_previous_errors = function(){
      $('form').find('.form-errors').html('');
      $('form .form-group').removeClass('has-error');
    }
  };

}(jQuery));
