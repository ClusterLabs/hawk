// Copyright (c) 2015-2016 Kristoffer Gronlund <kgronlund@suse.com>
// Copyright (c) 2016 Ayoub Belarbi <abelarbi@suse.com>
// See COPYING for license.

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

// render table-based visualizations for cluster status (Using JsRender).
var statusTable = {
  tableData: [], // An Array that contains JSON data fetched from the cib, see cacheData()
  tableAttrs: [], // JSON data that Contains attributes like ids and classes for specific elements in the table
  init: function(clusterId, cibData) { // init function called using: "statusTable.init(fetchedData);"
    this.clusterRefresh(clusterId, cibData);
  },
  indicator: function(clusterId, state) {
    var tag = $('#' + clusterId + ' .panel-heading .panel-title #refresh');
    if (state == "ok") {
      tag.html('<i class="fa fa-check"></i>');
    } else if (state == "refresh") {
      tag.html('<i class="fa fa-refresh fa-pulse-opacity"></i>');
    } else if (state == "blank") {
      tag.html('');
    } else if (state == "error") {
      tag.html('<i class="fa fa-exclamation-triangle"></i>');
    }
  },
  status_class_for: function(status) {
    if (status == "ok") {
      return "circle-success";
    } else if (status == "errors") {
      return "circle-danger";
    } else if (status == "maintenance") {
      return "circle-info";
    } else {
      return "circle-warning";
    }
  },
  status_icon_for: function(status) {
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
  },
  isRemote: function(cib, node) {
    return ("remote_nodes" in cib) && (node in cib["remote_nodes"]);
  },
  scheduleReconnect: function(clusterInfo, cb, time) {
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
  },
  displayClusterStatus: function(clusterId, cib) {
    if (cib.meta.status == "ok") {
      this.indicator(clusterId, "ok");
    } else {
      this.indicator(clusterId, "error");
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
        this.status_class_for(cib.meta.status) + '">' +
        this.status_icon_for(cib.meta.status) + '</div>';

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

      var cs = checksum(text + JSON.stringify(cib));
      if (tag.data('hash') != cs) {
        tag.html(text);
        tag.data('hash', cs);
        // Table rendering:
        // statusTable.init(clusterId, cib); // TODO
        this.displayTable(clusterId, cib);
      }
  },
  clusterConnectionError: function(clusterId, clusterInfo, xhr, status, error, cb) {
    if (window.userIsNavigatingAway)
      return;
    var msg = "";
    if (xhr.readyState > 1) {
      if (xhr.status == 403) {
        msg += __('Permission denied. ');
        var json = this.json_from_request(xhr);
        if (json && json.errors) {
          var merged = [];
          merged = merged.concat.apply(merged, json.errors);
          msg += merged.join(", ");
        }
      } else {
        var json = this.json_from_request(xhr);
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

    this.indicator(clusterId, "error");
    $('#' + clusterId).removeClass('panel-warning').addClass('panel-danger');
    var tag = $('#' + clusterId + ' div.panel-body');

    var errors = tag.find('.cluster-errors');

    errors.html('<div class="alert alert-danger">' +  msg +  "</div>");

    // force a refresh next time
    tag.data('hash', null);

    tag.find('.circle').addClass('circle-danger').removeClass('circle-success circle-info circle-warning').html(this.status_icon_for('errors'));

    this.scheduleReconnect(clusterInfo, cb);

    var btn = tag.find('button.btn')
    btn.text(__('Cancel'));
    btn.off('click');
    btn.removeClass('btn-success').addClass('btn-default');
    btn.attr("disabled", false);
    btn.click(function() {
      this.scheduleReconnect(clusterInfo);
      tag.html(this.basicCreateBody(clusterId, clusterInfo));

      if (clusterInfo.host == null) {
        this.clusterRefresh(clusterId, clusterInfo);
      } else {
        tag.find("button.btn").click(function() {
          var username = tag.find("input[name=username]").val();
          var password = tag.find("input[name=password]").val();
          tag.find('.btn-success').attr('disabled', true);
          tag.find('input').attr('disabled', true);
          clusterInfo.username = username;
          clusterInfo.password = password;
          this.startRemoteConnect(clusterId, clusterInfo);
        });
      }
    });

  },
  json_from_request: function(request) {
    try {
      return $.parseJSON(request.responseText);
    } catch (e) {
      // This'll happen if the JSON is malformed somehow
      return null;
    }
  },
  baseUrl: function(clusterInfo) {
    if (clusterInfo.host == null) {
      return "";
    } else {
      var transport = clusterInfo.https ? "https" : "http";
      var port = clusterInfo.port || "7630";
      return transport + "://" + clusterInfo.host + ":" + port;
    }
  },
  ajaxQuery: function(spec) {
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
  },
  clusterRefresh: function(clusterId, clusterInfo) {
      var that = this;
      that.ajaxQuery({
        url: that.baseUrl(clusterInfo) + "/cib/live?format=json",
        type: "GET",
        data: { _method: 'show' },
        crossDomain: clusterInfo.host != null,
        success: function(data) {
          $.each(data.nodes, function(node, node_values) {
            if (!that.isRemote(data, node_values.uname)) {
              if ($.inArray(clusterInfo.reconnections, node_values.uname) === -1) {
                clusterInfo.reconnections.push(node_values.uname);
              }
            }
          });
        that.displayClusterStatus(clusterId, data);
        $("#" + clusterId).data('epoch', data.meta.epoch);
        that.clusterUpdate(clusterId, clusterInfo);
      },
      error: function(xhr, status, error) {
        var tag = $('#' + clusterId + ' div.panel-body');
        if (clusterInfo.host != null && clusterInfo.password == null) {
          tag.html(this.basicCreateBody(clusterId, clusterInfo));
          this.indicator(clusterId, "blank"); // Remove the refresh icon after creating the connection form.
          var btn = tag.find("button.btn");
          btn.attr("disabled", false);
          btn.click(function() {
            var username = tag.find("input[name=username]").val();
            var password = tag.find("input[name=password]").val();
            tag.find('.btn-success').attr('disabled', true);
            tag.find('input').attr('disabled', true);
            clusterInfo.username = username;
            clusterInfo.password = password;
            this.startRemoteConnect(clusterId, clusterInfo);
          });
        } else {
          this.clusterConnectionError(clusterId, clusterInfo, xhr, status, error, function() {
            if (clusterInfo.host == null) {
              this.clusterRefresh(clusterId, clusterInfo);
            } else if (("reconnections" in clusterInfo) && clusterInfo.reconnections.length > 1) {
              var currHost = clusterInfo.host;
              var currFirst = clusterInfo.reconnections[0];
              clusterInfo.reconnections.splice(0, 1);
              clusterInfo.reconnections.push(currHost);
              clusterInfo.host = currFirst;
              if (currFirst == null) {
                this.clusterRefresh(clusterId, clusterInfo);
              } else {
                this.startRemoteConnect(clusterId, clusterInfo);
              }
            } else {
              this.clusterRefresh(clusterId, clusterInfo);
            }
          });
        }
      }
    });
  },
  clusterUpdate: function(clusterId, clusterInfo) {
    var current_epoch = $("#" + clusterId).data('epoch');
    this.ajaxQuery({
      url: this.baseUrl(clusterInfo) + "/monitor.json",
      type: "GET",
      data: current_epoch,
      timeout: 90000,
      crossDomain: clusterInfo.host != null,
      success: function(data) {
        if (data.epoch != current_epoch) {
          this.clusterRefresh(clusterId, clusterInfo);
        } else {
          this.clusterUpdate(clusterId, clusterInfo);
        }
      },
      error: function(xhr, status, error) {
        this.clusterConnectionError(clusterId, clusterInfo, xhr, status, error, function() {
          this.clusterRefresh(clusterId, clusterInfo);
        });
      }
    });
  },
  startRemoteConnect: function(clusterId, clusterInfo) {
    this.indicator(clusterId, "refresh");

    var username = clusterInfo.username || "hacluster";
    var password = clusterInfo.password;

    if (password === null) {
      this.clusterConnectionError(clusterId, clusterInfo, { readyState: 1, status: 0 }, "error", "", function() {});
      return;
    }

    this.ajaxQuery({
      url: this.baseUrl(clusterInfo) + "/login.json",
      crossDomain: true,
      type: "POST",
      data: {"session": {"username": username, "password": password } },
      success: function(data) {
        this.clusterRefresh(clusterId, clusterInfo);
      },
      error: function(xhr, status, error) {
        this.clusterConnectionError(clusterId, clusterInfo, xhr, status, error, function() {
          if (("reconnections" in clusterInfo) && clusterInfo.reconnections.length > 1) {
            var currHost = clusterInfo.host;
            var currFirst = clusterInfo.reconnections[0];
            clusterInfo.reconnections.splice(0, 1);
            clusterInfo.reconnections.push(currHost);
            clusterInfo.host = currFirst;
          }
          if (clusterInfo.host == null) {
            this.clusterRefresh(clusterId, clusterInfo);
          } else {
            this.startRemoteConnect(clusterId, clusterInfo);
          }
        });
      }
    });
  },
  basicCreateBody: function(clusterId, data) {
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
  },

  // Render the table:
  displayTable: function(clusterId, cibData){
    this.alterData(cibData); // Specify which nodes the resources are not running on: e.g {running_on: {node1: "started". node2: "slave", webui: "not_running"}}.
    this.cacheData(cibData);  // Cache data fetched from server, so it won't be necessary to pass the reference of the object each time
    this.cacheDom(clusterId); // Cache Dom elements to maximize performance
    this.initHelpers(); // Intialize helper methods for using them inside the template in "dashboards/show.html.erb
    this.render(); // Renders the table using the template in "dashboards/show.html.erb"
    //this.applyStyles(); // Set the appropriate classes after rendering the table (using tableAttrs)
    this.FormatClusterName(); // Set the title attribute for the cluster name to show cluster details
    this.printLog(); // Testing
  },
  alterData: function(cibData) {
    $.each(cibData.nodes, function(node_key, node_value) {
      $.each(cibData.resources, function(resource_key, resource_value){
        if(!(node_value.name in resource_value.running_on)){
          cibData.resources[resource_key]["running_on"][node_value.name] = "not_running";
        };
      });
    });
  },
  cacheData: function(cibData) {
    this.tableData = cibData;
  },
  cacheDom: function(clusterId) {
    this.$container = $('#dashboard-container');
    this.$table = this.$container.find("#" + clusterId); // this.$table is the div where the table will be rendred
    this.$template = this.$container.find("#status-table-template");
  },
  render: function() {
    $.templates('myTmpl', { markup: "#status-table-template", allowCode: true });
    this.$table.html( $.render.myTmpl(this.tableData)).show();
  },
  initHelpers: function() {
    // Using $.proxy to correctly pass the context to saveAttrs:
    // $.views.helpers({ saveAttrs: $.proxy(this.saveAttrs, this) });
  },
  FormatClusterName: function(){
    // Adding title to cluster name cell in the table and adding the information icon next to it
    var meta = this.tableData.meta;
    var title_value = "Status:\b" + meta.status +
                      "\nEpoch:\b" + meta.epoch +
                      "\nUpdate Origin:\b" + meta.update_origin +
                      "\nUpdate User:\b" + meta.update_user +
                      "\nStack:\b" + meta.stack;
    var info_icon = '&nbsp;<i class="fa fa-info-circle" aria-hidden="true"></i>';
    this.$table.find(".table-cluster-name").attr("title", title_value).append(info_icon);
  },
  printLog: function() {
    console.log(JSON.stringify(this.tableData));
  },
  // Helper methods (called from the template in dashboards/show.html.erb):
  // saveAttrs: function(type, id, className) {
  //   var objects = {"type": type, "id": id, "className": className};
  //   this.tableAttrs.push(objects);
  // },
  // applyStyles: function() {
  //    $.each(this.tableAttrs, function(index, element){
  //      $(element.id).attr("class", element.className);
  //    });
  // },

};
