// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// Copyright (c) 2015-2016 Kristoffer Gronlund <kgronlund@suse.com>
// Copyright (c) 2016 Ayoub Belarbi <abelarbi@suse.com>
// See COPYING for license.

;(function($) {
  window.dashboardAddCluster = function(status_wrapper) {
    // Each element has to have a "status-table" class and a "cluster" data attribute in order for the status table to be displayed.
    $(status_wrapper).find(".status-table").each(function(index, element){
      var clusterId = $(this).attr("id");
      var clusterData = $(this).data("cluster");
      var title = clusterData.name || __("Local Status");
      clusterData.conntry = null;
      clusterData.reconnections = [];
      clusterData.username = null;
      clusterData.password = null;

      var content = '<div class="cluster-errors"></div>';

      var text = [
        '<div id="inner-',  clusterId, '" class="panel panel-default" data-epoch="">',
        '<div class="panel-heading">',
        '<h3 class="panel-title">',
        '<span id="refresh"><i class="fa fa-refresh fa-pulse-opacity"></i></span> ',
        '<a href="', statusTable.baseUrl(clusterData), '/">', title, '</a>'
      ].join('');

      if (clusterData.host != null) {
        var s_remove = __('Remove cluster _NAME_ from dashboard?').replace('_NAME_', clusterData.name);
        text = text +
          '<form action="/dashboard/remove" method="post" accept-charset="UTF-8" data-remote="true" class="pull-right">' +
          '<input type="hidden" name="name" value="' + escape(clusterData.name) + '">' +
          '<button type="submit" class="close" data-confirm="' + s_remove + '"' +
          ' aria-label="Close"><span aria-hidden="true">&times;</span></button>' +
          '</form>';
      }
      text = text +
        '</h3>' +
        '</div>' +
        '<div class="panel-body">' +
        content +
        '</div>' +
        '</div>';

      $(this).append(text);

      statusTable.init("inner-" + clusterId, clusterData);
    });
  };

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
      dashboardAddCluster(data);
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
