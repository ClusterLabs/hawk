// Copyright (c) 2015-2016 Kristoffer Gronlund <kgronlund@suse.com>
// Copyright (c) 2016 Ayoub Belarbi <abelarbi@suse.com>
// See COPYING for license.

// render table-based visualizations for cluster status (Using JsRender).
var statusTable = {
  tableData: [], // An Array that contains JSON data fetched from the cib, see cacheData()
  tableAttrs: [], // JSON data that Contains attributes like ids and classes for specific elements in the table
  init: function(cibData) { // init function called using: "statusTable.init(fetchedData);"
    this.alterData(cibData); // Specify which nodes the resources are not running on: e.g {running_on: {node1: "started". node2: "slave", webui: "not_running"}}.
    this.cacheData(cibData);  // Cache data fetched from server, so it won't be necessary to pass the reference of the object each time
    this.cacheDom(); // Cache Dom elements to maximize performance
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
  cacheDom: function() {
    this.$container = $('#dashboard-container');
    this.$table = this.$container.find("#status-table"); // this.$table is the div where the table will be rendred
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
};
