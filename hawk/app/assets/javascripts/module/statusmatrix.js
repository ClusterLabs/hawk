// Copyright (c) 2015-2016 Kristoffer Gronlund <kgronlund@suse.com>
// Copyright (c) 2016 Ayoub Belarbi <abelarbi@suse.com>
// See COPYING for license.

// render table-based visualizations for cluster status (Using JsRender).
var statusTable = {
    tableData: [], // An Array that contains JSON data fetched from the cib, see cacheData()
    tableAttrs: [], // JSON data that Contains attributes like ids and classes for specific elements in the table
    init: function(cibData) { // init function called using: "statusTable.init(fetchedData);"
      this.cacheData(cibData);  // Cache data fetched from server
      this.cacheDom(); // Cache Dom elements to maximize performance
      this.initHelpers(); // Intialize helper methods for using them inside the template in "dashboards/show.html.erb
      this.render(); // Renders the table using the template in "dashboards/show.html.erb"
      this.applyStyles(); // Set the appropriate classes after rendering the table (using tableAttrs)
      this.printLog(); // Testing
    },
    cacheData: function(cibData) {
      this.tableData = cibData;
    },
    cacheDom: function() {
      this.$container = $('#dashboard-container');
      this.$table = this.$container.find("#status-table");
    },
    render: function() {
      $.templates('myTmpl', { markup: "#status-table-template", allowCode: true });
      this.$table.html( $.render.myTmpl(this.tableData)).show();
    },
    initHelpers: function() {
      // Using $.proxy to correctly pass the context to saveAttrs:
      $.views.helpers({ saveAttrs: $.proxy(this.saveAttrs, this) });
    },
    // Helper methods (called from the template in dashboards/show.html.erb):
    saveAttrs: function(type, id, className) {
      var objects = {"type": type, "id": id, "className": className};
      this.tableAttrs.push(objects);
    },
    applyStyles: function() {
       $.each(this.tableAttrs, function(index, element){
        $(element.id).attr("class", element.className)
       });
    },
    printLog: function() {
      console.log(JSON.stringify(this.tableData));
    },
  };


// render canvas-based visualizations for cluster status.
$(function() {
  $.fn.cibStatusMatrix = function(status, options) {
    var firstelement = null;
    if (status.resources.length == 0 && status.tickets.length == 0) {
      return;
    } else if (status.resources.length == 0) {
      firstelement = status.tickets[0];
    } else {
      firstelement = status.resources[0];
    }
    firstelement = ['<th class="status-matrix-element status-matrix-resource">',
                    firstelement.name,
                    '</th>'].join('');

    $(this).wrap('<table class="status-matrix-wrapper"><tbody></tbody></table>');
    $(this).wrap('<tr></tr>')
      .wrap([
        '<td class="dash-cell" rowspan="',
        status.resources.length + status.tickets.length,
        '"></td>'
      ].join(''));
    var canvas = this.get(0);
    var ctx = canvas.getContext("2d");

    // td -> tr -> tbody
    var wrapper = this.closest('tbody');

    var thetable = this.closest('table');
    thetable.attr('width', thetable.parent().width());
    $(window).on('resize', function() {
      thetable.attr('width', thetable.parent().width());
    });

    this.closest('tr').prepend(firstelement);

    var resourceheaders = [];
    $.each(status.resources, function(i, r) {
      if (i > 0) {
        resourceheaders.push('<tr><th class="status-matrix-element status-matrix-resource">', r.name, '</th></tr>');
      }
    });
    $.each(status.tickets, function(i, t) {
      if (status.resources.length > 0 || i > 0) {
        resourceheaders.push('<tr><th class="status-matrix-element status-matrix-ticket">', t.name, '</th></tr>');
      }
    });
    wrapper.append(resourceheaders.join(''));


    var defaults = {
      colors: {
        master: "#00aeef",
        started: "#7ac143",
        slave: "#f8981d",
        stopped: "#d9534f",
        pending: "#ffd457",
        failed: "#ed1c24",
        online: "#d0e4a6",
        standby: "#747678",
        offline: "#e4e5e6",
        unclean: "#ff0051",
        granted: "#c1d82f",
        revoked: "#b5bbd4",
        elsewhere: "#ffd457"
      },
      icons: {
        master: "fa-circle text-info",
        started: "fa-circle text-success",
        slave: "fa-circle text-warning",
        stopped: "fa-minus-circle text-danger",
        pending: "fa-question-circle text-warning",
        failed: "fa-times-circle text-danger",
        online: "fa-circle-thin text-success",
        standby: "fa-dot-circle-o text-warning",
        offline: "fa-minus-circle text-muted",
        unclean: "fa-warning text-danger",
        granted: "fa-check-circle text-success",
        revoked: "fa-times-circle-o text-muted",
        elsewhere: "fa-question-circle text-warning",
      },
      title: __("Details"),
      info_selector: "#cib-status-matrix-details",
      info_template: [
        '<div class="media" style="max-width: 320px;">',
        '<div class="media-left media-middle">',
        '{{if item}}',
        '<i class="fa fa-4x fa-fw {{>item_icon}}"></i>',
        '{{/if}}',
        '{{if !item && node}}',
        '<i class="fa fa-4x fa-fw {{>node_icon}}"></i>',
        '{{/if}}',
        '</div>',
        '<div class="media-body">',
        '<div class="container-fluid">',
        '<div class="row">',
        '<div class="col-md-12">',
        '{{if item}}{{:item.name}}{{/if}}&nbsp;',
        '{{if item}}<span class="label label-info pull-right">{{:item.state}}</span>{{/if}}&nbsp;',
        '</div>',
        '</div>',
        '<div class="row text-muted">',
        '<div class="col-md-12">',
        '{{if node}}{{:node.name}}{{/if}}&nbsp;',
        '{{if node}}<span class="label label-default pull-right">{{:node.state}}</span>{{/if}}&nbsp;',
        '</div>',
        '</div>',
        '</div>',
        '</div>',
      ].join('')
    };
    if (options === undefined) {
      options = defaults;
    } else {
      $.extend(defaults, options);
      options = defaults;
    }

    var colorByState = options.colors;

    var renderItem = function(x, y, w, h, node, item) {
      var inset = 2;
      ctx.lineWidth = 2;
      var hasStroke = false;
      var hasFill = false;

      if (item != null) {
        if (item.state in colorByState) {
          hasFill = true;
          ctx.fillStyle = colorByState[item.state];
        }
      }

      if (node != null && node.state in colorByState) {
        hasStroke = true;
        ctx.strokeStyle = colorByState[node.state];
      } else {
        ctx.strokeStyle = null;
      }

      if (hasFill && hasStroke) {
        ctx.fillRect(x + inset + 1, y + inset + 1, w - inset*2 - 2, h - inset*2 - 2);
        ctx.strokeRect(x + inset, y + inset, w - inset*2, h - inset*2);
      } else if (hasFill && !hasStroke) {
        ctx.fillRect(x + inset, y + inset, w - inset*2, h - inset*2);
      } else if (!hasFill && hasStroke) {
        ctx.fillStyle = ctx.strokeStyle;
        ctx.fillRect(x + inset, y + inset, w - inset*2, h - inset*2);
      } else {
        ctx.strokeStyle = options.colors.offline;
        ctx.strokeRect(x + inset, y + inset, w - inset*2, h - inset*2);
      }
    };


    var width = $(this).attr("width") || 320;
    var height = $(this).attr("height") || 240;
    var ncols = status.nodes.length + 1;
    var nrows = Math.max(status.resources.length + status.tickets.length, 1);

    var columns = [];
    for (var i = 0; i < status.nodes.length; ++i) {
      if (!status.nodes[i].remote) {
        columns.push({name: status.nodes[i].name, state: status.nodes[i].state, remote: false, row: []});
        columns[columns.length-1].row.length = nrows;
      }
    }
    var numremotes = 0;
    for (var i = 0; i < status.nodes.length; ++i) {
      if (status.nodes[i].remote) {
        numremotes = numremotes + 1;
        columns.push({name: status.nodes[i].name, state: status.nodes[i].state, remote: true, row: []});
        columns[columns.length-1].row.length = nrows;
      }
    }
    var totalspacings = 10;
    if (numremotes > 0) {
      totalspacings += 10;
    }
    var cellw = (width - totalspacings) / ncols;
    var cellh = height / nrows;
    var stopped = {name: "", remote: false, state: null, row: []}
    columns.push(stopped);

    $.each(columns, function(col, node) {
      var colx = col*cellw;
      if (node.remote) {
        colx += 10;
      } else if (col == columns.length - 1) {
        colx += totalspacings;
      }
      $.each(status.resources, function(row, rsc) {
        var hasInstance = false;
        if ("instances" in rsc) {
          for (var i = 0; i < rsc.instances.length; i++) {
            if (!hasInstance && rsc.instances[i].node == node.name) {
              hasInstance = true;
              var inst = {name: rsc.name, state: rsc.instances[i].state};
              node.row[row] = inst;
              renderItem(colx, row*cellh, cellw, cellh, node, inst);
            }
          }

          if (rsc.instances.length == 0 && !("_stopped" in rsc)) {
            rsc._stopped = true;
            var srsc = {name: rsc.name, state: "stopped"};
            stopped.row[row] = srsc;
            if (col == ncols - 1) {
              hasInstance = true;
            }
            renderItem((ncols-1)*cellw + totalspacings, row*cellh, cellw, cellh, stopped, srsc);
          }
        }
        if (!hasInstance) {
          renderItem(colx, row*cellh, cellw, cellh, node, null);
        }
      });
    });

    var toffset = status.resources.length;
    $.each(status.tickets, function(trow, ticket) {
      var row = trow + toffset;
      columns[0].row[row] = ticket;
      renderItem(0*cellw, row*cellh, width, cellh, null, ticket);
    });

    var lasthitx = null;
    var lasthity = null;

    var infoTmpl = $.templates(options.info_template);

    this.on("mousemove", function(event) {
      var rx = event.pageX - $(this).offset().left;
      var ry = event.pageY - $(this).offset().top;

      // compensate for column spacing
      var xoffset = 0;
      if (numremotes > 0 && rx > (ncols - numremotes - 1)*cellw)
        xoffset += 10;
      if (rx > (ncols - 1)*cellw)
        xoffset += 10;

      var hitx = Math.floor((rx - xoffset) / cellw);
      var hity = Math.floor(ry / cellh);
      var hitc = columns[hitx];
      if (hitc) {
        var hitr = hitc.row[hity];
        if (lasthitx != hitx || lasthity != hity) {
          var data = { title: options.title, node: null, item: null };
          if (hity >= status.resources.length) {
            hitr = columns[0].row[hity];
          } else {
            data.node = hitc;
            data.node_icon = options.icons[hitc.state || "offline"];
          }
          data.item = hitr;
          if (hitr) {
            data.item_icon = options.icons[hitr.state || "stopped"];
          } else {
            data.item_icon = options.icons["stopped"];
          }

          var abshitx = $(this).offset().left + hitx*cellw + xoffset;
          var abshity = $(this).offset().top + hity*cellh;
          var target = $(options.info_selector);
          target.html(infoTmpl.render(data)).width("auto");
          /*
          if (abshitx + (cellw / 2) > $(window).width() / 2) {
            target.addClass("right").removeClass("left").offset({left: abshitx - 16 - target.outerWidth(), top: abshity - 16});
          } else {
            target.removeClass("right").addClass("left").offset({left: abshitx + cellw + 16, top: abshity - 16});
          }
          */
          target.offset({left: abshitx + (cellw + 4) - target.outerWidth(), top: abshity + cellh + 14});
        }
      }
      lasthitx = hitx;
      lasthity = hity;
    }).on("mouseleave", function(event) {
      $(options.info_selector).fadeOut(200);
    }).on("mouseenter", function(event) {
      $(options.info_selector).fadeIn(200);
    });
  };
});
