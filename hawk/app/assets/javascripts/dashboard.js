// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

// https://<host>:7630/cib/mini.json

var dashboardAddCluster = (function() {

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
      return __('%{op} failed on _NODE_} (rc=_RC_, reason=_REASON_)').replace('_OP_', op).replace('_NODE_', node).replace('_RC_', rc).replace('_REASON_', reason);
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
      tag.html('<i class="fa fa-refresh fa-spin"></i>');
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
      cib.errors.forEach(function(err) {
        var type = err.type || "danger";
        text += "<div class=\"alert alert-" + type + "\">" + err.msg + "</div>";
      });
      text += '</div>';
      text += '</div>';
    }

    text += '<div class="row">';
    text += '<div class="col-md-12">';
    text += '<div class="list-group">';

    var makePopoverButton = function(id, content, cls, title) {
      var body = "";
      body += '<a tabindex="0" id="' + id + '" type="button" style="width: 100%;" class="btn list-group-item ' + cls + '" ';
      body += 'data-trigger="focus" data-toggle="popover" title="' + title + '" ';
      body += 'data-content="" ';
      body += '>';
      body += content;
      body += '</a>';
      return body;
    };

    var dlBegin = function() {
      return '<dl class="dl-horizontal">';
    };

    var dlEnd = function() {
      return '</dl>';
    };

    var dlAdd = function(title, text) {
      return '<dt>' + title + '</dt><dd>' + text + '</dd>';
    }

    var descCache = {};

    $.each(cib.tickets, function(idx, obj) {
      $.each(obj, function(ticket, state) {
        var details = dlBegin();
        $.each(cib.booth, function(typ, lst) {
          if (lst && lst.length > 0) {
            details += dlAdd(typ, lst.join(", "));
          }
        });
        details += dlEnd();
        var id = 'ticket_' + ticket + '_' + state;
        descCache[id] = details;

        text += makePopoverButton(id, 'Ticket ' + ticket + ' is <tt>' + state + '</tt>',
                                  "list-group-item-info", __("Details"));
      });
    });

    $.each(cib.node_states, function(state, count) {
      if (count > 0) {
        var details = dlBegin();
        $.each(cib.nodes, function(n, v) {
          if (state == v) {
            details += dlAdd(n, v);
          }
        });
        details += dlEnd();
        descCache['node_btn_' + state] = details;

        text += makePopoverButton('node_btn_' + state, count + ' ' + state + ' ' + plural('node', count),
                                  listGroupClassForState(state), __("Details"));
      }
    });

    $.each(cib.resource_states, function(state, count) {
      if (count > 0) {
        var details = dlBegin();
        $.each(cib.resources, function(rsc, locs) {
          if (state == "stopped" && $.isEmptyObject(locs)) {
            details += dlAdd(rsc, "<em>[stopped]</em>");
          } else {
            var active = "";
            $.each(locs, function(node, st) {
              if (st == state) {
                active += node + " ";
              }
            });
            if (active != "")
              details += dlAdd(rsc, active);
          }
        });
        details += dlEnd();
        descCache['rsc_btn_' + state] = details;

        text += makePopoverButton('rsc_btn_' + state, count + ' ' + state + ' ' + plural('resource', count),
                                  listGroupClassForState(state), __("Details"));
      }
    });

    $.each(cib.ticket_states, function(state, count) {
      if (count > 0) {
        var details = dlBegin();
        $.each(cib.tickets, function(i, e) {
          $.each(e, function(name, tstate) {
            if (state == tstate) {
              details += dlAdd(name, state);
            }
          });
        });
        details += dlEnd();
        descCache['ticket1_btn_' + state] = details;

        text += makePopoverButton('ticket1_btn_' + state, count + ' ' + state + ' ' + plural('ticket', count),
                                  listGroupClassForState(state), __("Details"));
      }
    });

    text += '</div>';
    text += '</div>';
    text += '</div>';

    var cs = checksum(text);

    if (tag.data('hash') != cs) {
      tag.html(text);
      tag.data('hash', cs);

      $.each(descCache, function(id, desc) {
        var btn = $('#' + clusterId + ' #' + id);
        btn.data("content", desc);
        btn.popover({animation: true, html: true});
      });
    }

  }

  function clusterConnectionError(clusterId, clusterInfo, xhr, status, error, cb) {
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

    tag.find('.circle').addClass('circle-danger').removeClass('circle-success circle-info circle-warning').html(status_icon_for('errors'));

    var next = window.setTimeout(cb, 15000);

    var btn = tag.find('button.btn')
    btn.text(__('Cancel'));
    btn.off('click');
    btn.removeClass('btn-success').addClass('btn-default');
    btn.attr("disabled", false);
    btn.click(function() {
      window.clearTimeout(next);
      tag.html(basicCreateBody(clusterId, clusterInfo));

      if (clusterInfo.host == null) {
        clusterRefresh(clusterId, clusterInfo);
      } else {
        tag.find("button.btn").click(function() {
          startRemoteConnect(clusterId, clusterInfo, tag);
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
      return transport + "://" + clusterInfo.host + ":" + clusterInfo.port;
    }
  }

  function ajaxQuery(spec) {
    var xhrfields = {};
    if (spec.crossDomain) {
      xhrfields.withCredentials = true;
    }

    $.ajax({ url: spec.url,
             beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
             contentType: 'application/x-www-form-urlencoded',
             dataType: 'json',
             data: spec.data || null,
             type: spec.type || "GET",
             timeout: 30000,
             crossDomain: spec.crossDomain || false,
             xhrFields: xhrfields,
             success: spec.success || null,
             error: spec.error || null
           });
  }

  function clusterRefresh(clusterId, clusterInfo) {
    indicator(clusterId, "refresh");

    ajaxQuery({ url: baseUrl(clusterInfo) + "/cib/mini.json",
                type: "GET",
                data: { _method: 'show' },
                crossDomain: clusterInfo.host != null,
                success: function(data) {
                  displayClusterStatus(clusterId, data);
                  window.setTimeout(function() { clusterRefresh(clusterId, clusterInfo); }, clusterInfo.interval*1000);
                },
                error: function(xhr, status, error) {
                  clusterConnectionError(clusterId, clusterInfo, xhr, status, error, function() {
                    clusterRefresh(clusterId, clusterInfo);
                  });
                }
              });
  }

  function startRemoteConnect(clusterId, clusterInfo, bodytag) {
    indicator(clusterId, "refresh");

    var username = bodytag.find("input[name=username]").val();
    var password = bodytag.find("input[name=password]").val();

    bodytag.find('.btn-success').attr('disabled', true);
    bodytag.find('input').attr('disabled', true);

    ajaxQuery({ url: baseUrl(clusterInfo) + "/login.json",
                crossDomain: true,
                type: "POST",
                data: {"session": {"username": username, "password": password } },
                success: function(data) {
                  clusterRefresh(clusterId, clusterInfo);
                },
                error: function(xhr, status, error) {
                  clusterConnectionError(clusterId, clusterInfo, xhr, status, error, function() {
                    startRemoteConnect(clusterId, clusterInfo, bodytag);
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
      content = '<div class="cluster-errors"></div>' +
        '<form class="form-horizontal" role="form" onsubmit="return false;">' +
        '<div class="input-group dashboard-login">' +
        '<span class="input-group-addon"><i class="fa fa-server"></i></span>' +
        '<input type="text" class="form-control" name="host" id="host" readonly="readonly" value="' + data.host + '">' +
        '</div>' +
        '<div class="input-group dashboard-login">' +
        '<span class="input-group-addon"><i class="glyphicon glyphicon-user"></i></span>' +
        '<input type="text" class="form-control" name="username" id="username" placeholder="' + s_username + '" value="' + v_username + '">' +
        '</div>' +
        '<div class="input-group dashboard-login">' +
        '<span class="input-group-addon"><i class="glyphicon glyphicon-lock"></i></span>' +
        '<input type="password" class="form-control" name="password" id="password" placeholder="' + s_password + '">' +
        '</div>' +
        '<div class="form-group">' +
        '<div class="col-sm-12 controls">' +
        '<button type="submit" class="btn btn-success">' +
        s_connect +
        '</button>' +
        '</div>' +
        '</div>' +
        '</form>';
    }
    return content;
  }

  return function(data) {
    var clusterId = newClusterId();
    var title = data.name || __("Local Status");

    var content = basicCreateBody(clusterId, data);

    var text = '<div class="col-lg-4 col-sm-6 col-xs-12">' +
        '<div id="' +
        clusterId +
        '" class="panel panel-default">' +
        '<div class="panel-heading">' +
        '<h3 class="panel-title">' +
        '<span id="refresh"></span> ' +
        '<a href="' + baseUrl(data) + '/">' + title + '</a>';
    if (data.host != null) {
      var s_remove = __('Remove cluster _NAME_ from dashboard?').replace('_NAME_', data.name);
      text = text +
        '<form action="/dashboard/remove" method="post" accept-charset="UTF-8" data-remote="true" class="pull-right">' +
        '<input type="hidden" name="name" value="' + escape(data.name) + '">' +
        '<button type="submit" class="close" onclick="' +
        "return confirm('" + s_remove + "');" +
        '" aria-label="Close"><span aria-hidden="true">&times;</span></button>' +
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

    if (data.host == null) {
      clusterRefresh(clusterId, data);
    } else {
      var close = $("#" + clusterId).find(".panel-title form");
      close.on("ajax:success", function(e, data) {
        $("#" + clusterId).remove();
        $.growl({ message: __('Cluster removed successfully.')}, {type: 'success'});
      });
      close.on("ajax:error", function(e, xhr, status, error) {
        $.growl({ message: __('Failed to remove cluster.')}, {type: 'danger'});
      });
      var body = $("#" + clusterId).find(".panel-body");
      body.find("button.btn").click(function() {
        startRemoteConnect(clusterId, data, body);
      });
    }
  };
})();

var dashboardSetupAddClusterForm = function() {
  $('form').find('span.toggleable').on('click', function (e) {
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
  $('form').on("ajax:success", function(e, data, status, xhr) {
    $('#modal').modal('hide');
    $('.modal-content').html('');
    dashboardAddCluster(data);
    $.growl({ message: __('Cluster added successfully.')}, {type: 'success'});
  }).on("ajax:error", function(e, xhr, status, error) {
    $(e.data).render_form_errors( $.parseJSON(xhr.responseText) );
  });

  (function($) {

    $.fn.render_form_errors = function(errors){

      this.clear_previous_errors();

      // show error messages in input form-group help-block
      var text = "";
      $.each(errors, function(field, messages) {
        text += "<div class=\"alert alert-danger\">";
        text += field + ': ' + messages.join(', ');
        text += "</div>";
      });

      $('form').find('.form-errors').html(text);

    };

    $.fn.clear_previous_errors = function(){
      $('form').find('.form-errors').html('');
    }
  }(jQuery));
};
