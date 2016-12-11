// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
// See COPYING for license.

// https://<host>:7630/cib/mini.json
;(function($) {
  var checksum = function(s) {
    var hash = 0, i, chr, len;
    if (s.length == 0) return hash;
    for (i = 0, len = s.length; i < len; i++) {
      chr   = s.charCodeAt(i);
      hash  = ((hash << 5) - hash) + chr;
      hash |= 0; // Convert to 32bit integer
    }
    return hash;
  };

  var GETTEXT = {
    error: function() {
      return __('Error');
    },
    err_unexpected: function(msg) {
      return __('Unexpected server error: _MSG_').replace('_MSG_', msg);
    },
    err_conn_failed: function() {
      return __('Connection to server failed (server down or network error - will retry every 15 seconds).');
    },
    err_conn_timeout: function() {
      return __('Connection to server timed out - will retry every 15 seconds.');
    },
    err_conn_aborted: function() {
      return __('Connection to server aborted - will retry every 15 seconds.');
    },
    err_denied: function() {
      return __('Permission denied');
    },
    err_failed_op: function(op, node, rc, reason) {
      return __('_OP_ failed on _NODE_} (rc=_RC_, reason=_REASON_)').replace('_OP_', op).replace('_NODE_', node).replace('_RC_', rc).replace('_REASON_', reason);
    }
  };


  var newClusterId = (function() {
    var id=0;
    return function() {
      if (arguments[0] === 0)
        id = 0;
      return "dashboard_cluster_" + id++;
    }
  })();

  function indicator(clusterId, state) {
    var tag = $('#' + clusterId + ' .panel-heading .panel-title #refresh');
    if (state == "ok") {
      tag.html('<i class="fa fa-check"></i>');
    } else if (state == "refresh") {
      tag.html('<i class="fa fa-refresh fa-pulse-opacity"></i>');
    } else if (state == "error") {
      tag.html('<i class="fa fa-exclamation-triangle"></i>');
    }
  }

  function status_class_for(status) {
    if (status == "ok") {
      return "circle-success";
    } else if (status == "errors") {
      return "circle-danger";
    } else if (status == "maintenance") {
      return "circle-info";
    } else {
      return "circle-warning";
    }
  }

  function status_icon_for(status) {
    if (status == "ok") {
      return '<i class="fa fa-check text"></i>';
    } else if (status == "errors") {
      return '<i class="fa fa-exclamation-triangle text"></i>';
    } else if (status == "maintenance") {
      return '<i class="fa fa-wrench text"></i>';
    } else if (status == "nostonith") {
      return '<i class="fa fa-plug text"></i>';
    } else {
      return '<i class="fa fa-question text"></i>';
    }
  }

  function plural(word, count) {
    if (count > 1) {
      return word + "s";
    } else {
      return word;
    }
  }

  function listGroupClassForState(state) {
    if (state == "online" || state == "granted" || state == "master" || state == "slave" || state == "started") {
      return "list-group-item-success";
    } else if (state == "offline" || state == "unclean" || state == "failed" || state == "stopped") {
      return "list-group-item-danger";
    } else {
      return "list-group-item-warning";
    }
  }

  function isRemote(cib, node) {
    return ("remote_nodes" in cib) && (node in cib["remote_nodes"]);
  }

  function scheduleReconnect(clusterInfo, cb, time) {
    if (clusterInfo.conntry !== null) {
      window.clearTimeout(clusterInfo.conntry);
      clusterInfo.conntry = null;
    }
    if (cb !== undefined) {
      if (time === undefined) {
        time = 15000;
      }
      clusterInfo.conntry = window.setTimeout(cb, time);
    }
  }

  function displayClusterStatus(clusterId, cib) {
    if (cib.meta.status == "ok") {
      indicator(clusterId, "ok");
    } else {
      indicator(clusterId, "error");
    }

    var tag = $('#' + clusterId + ' div.panel-body');

    if (cib.meta.status == "maintenance" || cib.meta.status == "nostonith") {
      $('#' + clusterId).removeClass('panel-default panel-danger').addClass('panel-warning');
    } else if (cib.meta.status == "errors") {
      $('#' + clusterId).removeClass('panel-default panel-warning').addClass('panel-danger');
    } else {
      $('#' + clusterId).removeClass('panel-warning panel-danger').addClass('panel-default');
    }

    var circle = '<div class="circle circle-medium ' +
        status_class_for(cib.meta.status) + '">' +
        status_icon_for(cib.meta.status) + '</div>';

    var text = "";

    if (cib.errors.length > 0) {
      text += '<div class="row">';
      text += '<div class="cluster-errors col-md-12">';
      text += '<ul class="list-group">';
      cib.errors.forEach(function(err) {
        var type = err.type || "danger";
        text += "<li class=\"list-group-item list-group-item-" + type + "\">" + err.msg + "</li>";
      });
      text += '</ul>';
      text += '</div>';
      text += '</div>';
    }

    text += '<div class="row">';
    text += '<div class="col-md-12 text-center dash-cluster-content">';

    var status_summary = {
      cluster_name: $('body').data('content').crm_config.cluster_name, // TODO to be changed to the cluster_name, since the cib object which is fetched from "/cib/live?mini=true&format=json" does not contain that, should be fetched from "/cib/live?format=json", see function "clusterRefresh"
      nodes: [],
      resources: [],
      tickets: []
    };

    $.each(cib.nodes, function(n, v) {
      status_summary.nodes.push({ name: n, state: v, remote: isRemote(cib, n) });
    });

    $.each(cib.resources, function(n, v) {
      var rsc = {name: n, instances: []};
      $.each(v, function(nn, vv) {
        rsc.instances.push({node: nn, state: vv});
      });
      status_summary.resources.push(rsc);
    });

    $.each(cib.tickets, function(n, v) {
      status_summary.tickets.push({name: n, state: v});
    });

    var cwidth = Math.min(status_summary.nodes.length * 36 + 36, 360) + 20;
    var cheight = status_summary.resources.length * 24 + status_summary.tickets.length * 24;

    text += '<canvas width="' + cwidth + '" height="' + cheight + '"></canvas>';

    text += '</div>';
    text += '</div>';

    var cs = checksum(text + JSON.stringify(status_summary));

    if (tag.data('hash') != cs) {
      tag.html(text);
      tag.data('hash', cs);
      tag.find('canvas').cibStatusMatrix(status_summary);
      statusTable.init(status_summary);

    }

  }

  function clusterConnectionError(clusterId, clusterInfo, xhr, status, error, cb) {
    if (window.userIsNavigatingAway)
      return;
    var msg = "";
    if (xhr.readyState > 1) {
      if (xhr.status == 403) {
        msg += __('Permission denied. ');
        var json = json_from_request(xhr);
        if (json && json.errors) {
          var merged = [];
          merged = merged.concat.apply(merged, json.errors);
          msg += merged.join(", ");
        }
      } else {
        var json = json_from_request(xhr);
        if (json && json.errors) {
          var merged = [];
          merged = merged.concat.apply(merged, json.errors);
          msg += merged.join(", ");
        } else if (xhr.status >= 10000) {
          msg += GETTEXT.err_conn_failed();
        } else {
          msg += GETTEXT.err_unexpected(xhr.status + " " + xhr.statusText);
        }
      }
    } else if (status == "error") {
      msg += __("Error connecting to server.");
    } else if (status == "timeout") {
      msg += __("Connection to server timed out.");
    } else if (status == "abort") {
      msg += __("Connection to server was aborted.");
    } else if (status == "parsererror") {
      msg += __("Server returned invalid data.");
    } else if (error) {
      msg += error;
    } else {
      msg += __("Unknown error connecting to server.");
    }

    msg += " " + __("Retrying every 15 seconds...");

    if (xhr.status != 0) {
      msg += "<pre> Response: " + xhr.status + " " + xhr.statusText + "</pre>";
    }

    indicator(clusterId, "error");
    $('#' + clusterId).removeClass('panel-warning').addClass('panel-danger');
    var tag = $('#' + clusterId + ' div.panel-body');

    var errors = tag.find('.cluster-errors');

    errors.html('<div class="alert alert-danger">' +  msg +  "</div>");

    // force a refresh next time
    tag.data('hash', null);

    tag.find('.circle').addClass('circle-danger').removeClass('circle-success circle-info circle-warning').html(status_icon_for('errors'));

    scheduleReconnect(clusterInfo, cb);

    var btn = tag.find('button.btn')
    btn.text(__('Cancel'));
    btn.off('click');
    btn.removeClass('btn-success').addClass('btn-default');
    btn.attr("disabled", false);
    btn.click(function() {
      scheduleReconnect(clusterInfo);
      tag.html(basicCreateBody(clusterId, clusterInfo));

      if (clusterInfo.host == null) {
        clusterRefresh(clusterId, clusterInfo);
      } else {
        tag.find("button.btn").click(function() {
          var username = tag.find("input[name=username]").val();
          var password = tag.find("input[name=password]").val();
          tag.find('.btn-success').attr('disabled', true);
          tag.find('input').attr('disabled', true);
          clusterInfo.username = username;
          clusterInfo.password = password;
          startRemoteConnect(clusterId, clusterInfo);
        });
      }
    });

  }

  function json_from_request(request) {
    try {
      return $.parseJSON(request.responseText);
    } catch (e) {
      // This'll happen if the JSON is malformed somehow
      return null;
    }
  }

  function baseUrl(clusterInfo) {
    if (clusterInfo.host == null) {
      return "";
    } else {
      var transport = clusterInfo.https ? "https" : "http";
      var port = clusterInfo.port || "7630";
      return transport + "://" + clusterInfo.host + ":" + port;
    }
  }

  function ajaxQuery(spec) {
    var xhrfields = {};
    if (spec.crossDomain) {
      xhrfields.withCredentials = true;
    }

    $.ajax({
      url: spec.url,
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      contentType: 'application/x-www-form-urlencoded',
      dataType: 'json',
      data: spec.data || null,
      type: spec.type || "GET",
      timeout: spec.timeout || 30000,
      crossDomain: spec.crossDomain || false,
      xhrFields: xhrfields,
      success: spec.success || null,
      error: spec.error || null
    });
  }

  function clusterRefresh(clusterId, clusterInfo) {
    indicator(clusterId, "refresh");

    ajaxQuery({
      url: baseUrl(clusterInfo) + "/cib/live?mini=true&format=json",
      type: "GET",
      data: { _method: 'show' },
      crossDomain: clusterInfo.host != null,
      success: function(data) {
        $.each(data.nodes, function(node, _state) {
          if (!isRemote(data, node)) {
            if ($.inArray(clusterInfo.reconnections, node) === -1) {
              clusterInfo.reconnections.push(node);
            }
          }
        });
        displayClusterStatus(clusterId, data);
        $("#" + clusterId).data('epoch', data.meta.epoch);
        clusterUpdate(clusterId, clusterInfo);
      },
      error: function(xhr, status, error) {
        var tag = $('#' + clusterId + ' div.panel-body');
        if (clusterInfo.host != null && clusterInfo.password == null) {
          tag.html(basicCreateBody(clusterId, clusterInfo));
          var btn = tag.find("button.btn");
          btn.attr("disabled", false);
          btn.click(function() {
            var username = tag.find("input[name=username]").val();
            var password = tag.find("input[name=password]").val();
            tag.find('.btn-success').attr('disabled', true);
            tag.find('input').attr('disabled', true);
            clusterInfo.username = username;
            clusterInfo.password = password;
            startRemoteConnect(clusterId, clusterInfo);
          });
        } else {
          clusterConnectionError(clusterId, clusterInfo, xhr, status, error, function() {
            if (clusterInfo.host == null) {
              clusterRefresh(clusterId, clusterInfo);
            } else if (("reconnections" in clusterInfo) && clusterInfo.reconnections.length > 1) {
              var currHost = clusterInfo.host;
              var currFirst = clusterInfo.reconnections[0];
              clusterInfo.reconnections.splice(0, 1);
              clusterInfo.reconnections.push(currHost);
              clusterInfo.host = currFirst;
              if (currFirst == null) {
                clusterRefresh(clusterId, clusterInfo);
              } else {
                startRemoteConnect(clusterId, clusterInfo);
              }
            } else {
              clusterRefresh(clusterId, clusterInfo);
            }
          });
        }
      }
    });
  }

  function clusterUpdate(clusterId, clusterInfo) {
    var current_epoch = $("#" + clusterId).data('epoch');
    ajaxQuery({
      url: baseUrl(clusterInfo) + "/monitor.json",
      type: "GET",
      data: current_epoch,
      timeout: 90000,
      crossDomain: clusterInfo.host != null,
      success: function(data) {
        if (data.epoch != current_epoch) {
          clusterRefresh(clusterId, clusterInfo);
        } else {
          clusterUpdate(clusterId, clusterInfo);
        }
      },
      error: function(xhr, status, error) {
        clusterConnectionError(clusterId, clusterInfo, xhr, status, error, function() {
          clusterRefresh(clusterId, clusterInfo);
        });
      }
    });
  }

  function startRemoteConnect(clusterId, clusterInfo) {
    indicator(clusterId, "refresh");

    var username = clusterInfo.username || "hacluster";
    var password = clusterInfo.password;

    if (password === null) {
      clusterConnectionError(clusterId, clusterInfo, { readyState: 1, status: 0 }, "error", "", function() {});
      return;
    }

    ajaxQuery({
      url: baseUrl(clusterInfo) + "/login.json",
      crossDomain: true,
      type: "POST",
      data: {"session": {"username": username, "password": password } },
      success: function(data) {
        clusterRefresh(clusterId, clusterInfo);
      },
      error: function(xhr, status, error) {
        clusterConnectionError(clusterId, clusterInfo, xhr, status, error, function() {
          if (("reconnections" in clusterInfo) && clusterInfo.reconnections.length > 1) {
            var currHost = clusterInfo.host;
            var currFirst = clusterInfo.reconnections[0];
            clusterInfo.reconnections.splice(0, 1);
            clusterInfo.reconnections.push(currHost);
            clusterInfo.host = currFirst;
          }
          if (clusterInfo.host == null) {
            clusterRefresh(clusterId, clusterInfo);
          } else {
            startRemoteConnect(clusterId, clusterInfo);
          }
        });
      }
    });
  }

  function basicCreateBody(clusterId, data) {
    var s_hostname = __('Hostname');
    var s_username = __('Username');
    var s_password = __('Password');
    var s_connect = __('Connect');
    var v_username = $('body').data('user');
    var content = '';
    if (data.host != null) {
      content = [
        '<div class="cluster-errors"></div>',
        '<form class="form-horizontal" role="form" onsubmit="return false;">',
        '<div class="form-group">',
        '<div class="col-sm-12">',
        '<div class="input-group dashboard-login">',
        '<span class="input-group-addon"><i class="fa fa-server"></i></span>',
        '<input type="text" class="form-control" name="host" id="host" readonly="readonly" value="', data.host, '">',
        '</div>',
        '</div>',
        '</div>',
        '<div class="form-group">',
        '<div class="col-sm-12">',
        '<div class="input-group dashboard-login">',
        '<span class="input-group-addon"><i class="glyphicon glyphicon-user"></i></span>',
        '<input type="text" class="form-control" name="username" id="username" placeholder="', s_username, '" value="', v_username, '">',
        '</div>',
        '</div>',
        '</div>',
        '<div class="form-group">',
        '<div class="col-sm-12">',
        '<div class="input-group dashboard-login">',
        '<span class="input-group-addon"><i class="glyphicon glyphicon-lock"></i></span>',
        '<input type="password" class="form-control" name="password" id="password" placeholder="', s_password, '">',
        '</div>',
        '</div>',
        '</div>',
        '<div class="form-group">',
        '<div class="col-sm-12 controls">',
        '<button type="submit" class="btn btn-success">',
        s_connect,
        '</button>',
        '</div>',
        '</div>',
          '</form>'
      ].join("");
    }
    return content;
  }

  var updateLayout = function() {
    var clusters = $("#clusters").children();
    var nclusters = clusters.length;
    if (nclusters == 1) {
      clusters.removeClass().addClass("col-md-10 col-md-offset-1 col-lg-8 col-lg-offset-2");
    } else if (nclusters == 2) {
      clusters.removeClass().addClass("col-md-6");
    } else if (nclusters == 3) {
      clusters.removeClass().addClass("col-md-6 col-lg-4");
    } else if (nclusters == 4) {
      clusters.removeClass().addClass("col-md-6");
    } else {
      clusters.removeClass().addClass("col-md-4");
    }
  };

  window.dashboardAddCluster = function(data) {
    var clusterId = newClusterId();
    var title = data.name || __("Local Status");
    data.conntry = null;
    data.reconnections = [];
    data.username = null;
    data.password = null;

    var content = '<div class="cluster-errors"></div>';

    var text = [
      '<div id="outer-',
      clusterId,
      '" class="col-lg-4 col-sm-6 col-xs-12">',
      '<div id="',  clusterId, '" class="panel panel-default" data-epoch="">',
      '<div class="panel-heading">',
      '<h3 class="panel-title">',
      '<span id="refresh"></span> ',
      '<a href="', baseUrl(data), '/">', title, '</a>'
    ].join('');

    if (data.host != null) {
      var s_remove = __('Remove cluster _NAME_ from dashboard?').replace('_NAME_', data.name);
      text = text +
        '<form action="/dashboard/remove" method="post" accept-charset="UTF-8" data-remote="true" class="pull-right">' +
        '<input type="hidden" name="name" value="' + escape(data.name) + '">' +
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
      '</div>' +
      '</div>';
    $("#clusters").append(text);

    updateLayout();

    clusterRefresh(clusterId, data);
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
