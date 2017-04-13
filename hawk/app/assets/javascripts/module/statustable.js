// Copyright (c) 2015-2016 Kristoffer Gronlund <kgronlund@suse.com>
// Copyright (c) 2016 Ayoub Belarbi <abelarbi@suse.com>
// See COPYING for license.

// This module is a table-based visualization for cluster status (Using JsRender). To use this module:
// 1. Require the statusTable module.
// 2. Create the template for the table(JsRender) with an id "#status-table-template".
// 3. Add the table wrapper(div with a class "status-wrapper" for example).
// 4. Inside the table wrapper, add for each cluster a div tag with a data attribute named "cluster".
// 5. The cluster data attribute's value should be set to "local_cluster" to fetch local cluster.
// 6. To fetch remote clusters, pass the cluster object(cluster model) as a value to the cluster data attribute.
// 7. Init the module with statusTable.init(".status-wrapper");


var statusTable = {
    tableData: [], // An Array that contains JSON data fetched from the cib, see cacheData()
    tableAttrs: [], // JSON data that Contains attributes like ids and classes for specific elements in the table
    clusterId: "",
    init: function(clusterId) { // init function called using: "statusTable.init(fetchedData);"
        // Each element has to have a "status-table" class and a "cluster" data attribute in order for the status table to be displayed.
            this.clusterId = clusterId;
            var clusterData = $("#" + this.clusterId).data("cluster");
            var title = clusterData.name || __("Local Status");
            clusterData.conntry = null;
            clusterData.reconnections = [];
            clusterData.username = null;
            clusterData.password = null;
            this.clusterRefresh(clusterData);
    },
    gettext_translate: function(type, options) {
        typeof(options) === "undefined" ? options = {}: options;
        var text = "";
        switch (type) {
            case 'error':
                text = __('Error');
                break;
            case 'err_unexpected':
                text = __('Unexpected server error: _MSG_').replace('_MSG_', options.error_msg);
                break;
            case 'err_conn_failed':
                text = __('Connection to server failed (server down or network error - will retry every 15 seconds).');
                break;
            case 'err_conn_timeout':
                text = __('Connection to server timed out - will retry every 15 seconds.');
                break;
            case 'err_conn_aborted':
                text = __('Connection to server aborted - will retry every 15 seconds.');
                break;
            case 'err_denied':
                text = __('Permission denied');
                break;
            case 'err_failed_op':
                text = __('_OP_ failed on _NODE_} (rc=_RC_, reason=_REASON_)').replace('_OP_', op).replace('_NODE_', node).replace('_RC_', rc).replace('_REASON_', reason);
                break;
        }
        return text;
    },
    checksum: function(s) {
        var hash = 0,
            i, chr, len;
        if (s.length == 0) return hash;
        for (i = 0, len = s.length; i < len; i++) {
            chr = s.charCodeAt(i);
            hash = ((hash << 5) - hash) + chr;
            hash |= 0; // Convert to 32bit integer
        }
        return hash;
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
    displayClusterStatus: function(cib) {

        var tag = $('#inner-' + this.clusterId + ' div.panel-body');

        if (cib.meta.status == "maintenance" || cib.meta.status == "nostonith") {
            $('#inner-' + this.clusterId).removeClass('panel-default panel-danger').addClass('panel-warning');
        } else if (cib.meta.status == "errors") {
            $('#inner-' + this.clusterId).removeClass('panel-default panel-warning').addClass('panel-danger');
        } else {
            $('#inner-' + this.clusterId).removeClass('panel-warning panel-danger').addClass('panel-default');
        }

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

        var cs = this.checksum(text + JSON.stringify(cib));
        if (tag.data('hash') != cs) {
            tag.html(text);
            tag.data('hash', cs);
            this.displayTable(cib);
        }
    },
    clusterConnectionError: function(clusterInfo, xhr, status, error, cb) {
        var that = this;
        if (window.userIsNavigatingAway)
            return;
        var msg = "";
        if (xhr.readyState > 1) {
            if (xhr.status == 403) {
                msg += __('Permission denied. ');
                var json = that.json_from_request(xhr);
                if (json && json.errors) {
                    var merged = [];
                    merged = merged.concat.apply(merged, json.errors);
                    msg += merged.join(", ");
                }
            } else {
                var json = that.json_from_request(xhr);
                if (json && json.errors) {
                    var merged = [];
                    merged = merged.concat.apply(merged, json.errors);
                    msg += merged.join(", ");
                } else if (xhr.status >= 10000) {
                    msg += that.gettext_translate("err_conn_failed");
                } else {
                    msg += that.gettext_translate("err_unexpected", {
                        error_msg: xhr.status + " " + xhr.statusText
                    });
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
        this.updateClusterTab("connectionError");
        $('#inner-' + this.clusterId).removeClass('panel-warning').addClass('panel-danger');
        var tag = $('#inner-' + this.clusterId + ' div.panel-body');

        var errors = tag.find('.cluster-errors');
        errors.html('<div class="alert alert-danger">' + msg + "</div>");

        // force a refresh next time
        tag.data('hash', null);

        that.scheduleReconnect(clusterInfo, cb);

        var btn = tag.find('button.btn')
        btn.text(__('Cancel'));
        btn.off('click');
        btn.removeClass('btn-success').addClass('btn-default');
        btn.attr("disabled", false);
        btn.click(function() {
            that.scheduleReconnect(clusterInfo);
            tag.html(that.basicCreateBody(clusterInfo));

            if (clusterInfo.host == null) {
                that.clusterRefresh(clusterInfo);
            } else {
                tag.find("button.btn").click(function() {
                    var username = tag.find("input[name=username]").val();
                    var password = tag.find("input[name=password]").val();
                    tag.find('.btn-success').attr('disabled', true);
                    tag.find('input').attr('disabled', true);
                    clusterInfo.username = username;
                    clusterInfo.password = password;
                    that.startRemoteConnect(clusterInfo);
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
            beforeSend: function(xhr) {
                xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
            },
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
    clusterRefresh: function(clusterInfo) {
        var that = this;
        that.ajaxQuery({
            url: that.baseUrl(clusterInfo) + "/cib/live?format=json",
            type: "GET",
            data: {
                _method: 'show'
            },
            crossDomain: clusterInfo.host != null,
            success: function(data) {
                $.each(data.nodes, function(node, node_values) {
                    if (!that.isRemote(data, node_values.uname)) {
                        if ($.inArray(clusterInfo.reconnections, node_values.uname) === -1) {
                            clusterInfo.reconnections.push(node_values.uname);
                        }
                    }
                });
                that.displayClusterStatus(data);
                $("#inner-" + that.clusterId).data('epoch', data.meta.epoch);
                that.clusterUpdate(clusterInfo);
            },
            error: function(xhr, status, error) {
                var tag = $('#inner-' + that.clusterId + ' div.panel-body');
                if (clusterInfo.host != null && clusterInfo.password == null) {
                    tag.html(that.basicCreateBody(clusterInfo));
                    var btn = tag.find("button.btn");
                    btn.attr("disabled", false);
                    btn.click(function() {
                        var username = tag.find("input[name=username]").val();
                        var password = tag.find("input[name=password]").val();
                        tag.find('.btn-success').attr('disabled', true);
                        tag.find('input').attr('disabled', true);
                        clusterInfo.username = username;
                        clusterInfo.password = password;
                        that.startRemoteConnect(clusterInfo);
                    });
                } else {
                    that.clusterConnectionError(clusterInfo, xhr, status, error, function() {
                        if (clusterInfo.host == null) {
                            that.clusterRefresh(clusterInfo);
                        } else if (("reconnections" in clusterInfo) && clusterInfo.reconnections.length > 1) {
                            var currHost = clusterInfo.host;
                            var currFirst = clusterInfo.reconnections[0];
                            clusterInfo.reconnections.splice(0, 1);
                            clusterInfo.reconnections.push(currHost);
                            clusterInfo.host = currFirst;
                            if (currFirst == null) {
                                that.clusterRefresh(clusterInfo);
                            } else {
                                that.startRemoteConnect(clusterInfo);
                            }
                        } else {
                            that.clusterRefresh(clusterInfo);
                        }
                    });
                }
            }
        });
    },
    clusterUpdate: function(clusterInfo) {
        var that = this;
        var current_epoch = $("#inner-" + that.clusterId).data('epoch');
        that.ajaxQuery({
            url: that.baseUrl(clusterInfo) + "/monitor.json",
            type: "GET",
            data: current_epoch,
            timeout: 90000,
            crossDomain: clusterInfo.host != null,
            success: function(data) {
                if (data.epoch != current_epoch) {
                    that.clusterRefresh(clusterInfo);
                } else {
                    that.clusterUpdate(clusterInfo);
                }
            },
            error: function(xhr, status, error) {
                that.clusterConnectionError(clusterInfo, xhr, status, error, function() {
                    that.clusterRefresh(clusterInfo);
                });
            }
        });
    },
    startRemoteConnect: function(clusterInfo) {
        var that = this;
        this.updateClusterTab("refresh");

        var username = clusterInfo.username || "hacluster";
        var password = clusterInfo.password;

        if (password === null) {
            that.clusterConnectionError(clusterInfo, {
                readyState: 1,
                status: 0
            }, "error", "", function() {});
            return;
        }

        that.ajaxQuery({
            url: that.baseUrl(clusterInfo) + "/login.json",
            crossDomain: true,
            type: "POST",
            data: {
                "session": {
                    "username": username,
                    "password": password
                }
            },
            success: function(data) {
                that.clusterRefresh(clusterInfo);
            },
            error: function(xhr, status, error) {
                that.clusterConnectionError(clusterInfo, xhr, status, error, function() {
                    if (("reconnections" in clusterInfo) && clusterInfo.reconnections.length > 1) {
                        var currHost = clusterInfo.host;
                        var currFirst = clusterInfo.reconnections[0];
                        clusterInfo.reconnections.splice(0, 1);
                        clusterInfo.reconnections.push(currHost);
                        clusterInfo.host = currFirst;
                    }
                    if (clusterInfo.host == null) {
                        that.clusterRefresh(clusterInfo);
                    } else {
                        that.startRemoteConnect(clusterInfo);
                    }
                });
            }
        });
    },
    basicCreateBody: function(data) {
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
    displayTable: function(cibData) {
        this.alterData(cibData); // Specify which nodes the resources are not running on: e.g {running_on: {node1: "started". node2: "slave", webui: "not_running"}}.
        this.cacheData(cibData); // Cache data fetched from server, so it won't be necessary to pass the reference of the object each time
        this.cacheDom(); // Cache Dom elements to maximize performance
        this.initHelpers(); // Intialize helper methods for using them inside the template in "dashboards/show.html.erb
        this.render(); // Renders the table using the template in "dashboards/show.html.erb"
        //this.applyStyles(); // Set the appropriate classes after rendering the table (using tableAttrs)
        this.formatClusterName(); // Set the title attribute for the cluster name to show cluster details
        this.updateClusterTab("connected"); // Update the cluster's status indicator shown next to the cluster name in each tab.
        this.printLog(); // Testing
    },
    alterData: function(cibData) {
        $.each(cibData.nodes, function(node_key, node_value) {
            $.each(cibData.resources, function(resource_key, resource_value) {
                if (!(node_value.name in resource_value.running_on)) {
                    cibData.resources[resource_key]["running_on"][node_value.name] = "not_running";
                };
            });
        });
    },
    cacheData: function(cibData) {
        this.tableData = cibData;
    },
    cacheDom: function() {
        this.$container = $('#dashboard-container');
        this.$table = this.$container.find("#inner-" + this.clusterId).find(".status-inner-table"); // this.$table is the div where the table will be rendred
        this.$template = this.$container.find("#status-table-template");
    },
    render: function() {
        $.templates('myTmpl', {
            markup: "#status-table-template",
            allowCode: true
        });
        this.$table.html($.render.myTmpl(this.tableData)).show();
    },
    initHelpers: function() {
        //Using $.proxy to correctly pass the context to printClusterId:
        $.views.helpers({ printClusterId: $.proxy(this.printClusterId, this) });
    },
    updateClusterTab: function(state) {
      var tab_id = "#" + this.clusterId + '-indicator';
      if (state == "connected") {
        if (this.tableData.meta.status == "ok") {
          $(tab_id).attr({class: "tab-cluster-status status-success", title: "Status: Ok"}).html('');
        } else if (this.tableData.meta.status == "errors") {
          $(tab_id).attr({class: "tab-cluster-status status-danger", title: "Status: Errors"}).html('');
        } else if ((this.tableData.meta.status == "maintenance")) {
          $(tab_id).attr({class: "", title: "Maintenance mode"}).html('<i class="fa fa-wrench"></i>');
        } else if ((this.tableData.meta.status == "nostonith")) {
          $(tab_id).attr({class: "", title: "Status: nostonith"}).html('<i class="fa fa-plug"></i>');
        } else {
          $(tab_id).attr({class: "tab-cluster-status status-offline"}).html('');
        }
      } else if (state == "connectionError"){
        $(tab_id).attr({class: "", title: "Status: connection error"}).html('<i class="fa fa-exclamation-triangle"></i>');
      }
      else if (state == "refresh"){
        $(tab_id).attr({class: ""}).html('<i class="fa fa-refresh fa-pulse-opacity">');
      }
    },
    formatClusterName: function() {
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
    printClusterId: function() {
      return this.clusterId;
    }
    // applyStyles: function() {
    //    $.each(this.tableAttrs, function(index, element){
    //      $(element.id).attr("class", element.className);
    //    });
    // }

};
