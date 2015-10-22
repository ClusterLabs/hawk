// Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
// See COPYING for license.

// render canvas-based visualizations for cluster status.


$(function() {
  $.fn.cibStatusMatrix = function(status, options) {
    var canvas = this.get(0);

    var ctx = canvas.getContext("2d");

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
          unclean: "#ec008c",
          granted: "#c1d82f",
          revoked: "#b5bbd4",
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
          unclean: "fa-circle text-danger",
          granted: "fa-check-circle text-success",
          revoked: "fa-times-circle-o text-muted",
        },
        title: __("Details"),
        info_selector: "#cib-status-matrix-details",
        info_template: [
          '{{if item}}',
          '<h2><i class="fa fa-2x {{>item_icon}}"></i> {{:item.name}} <small>{{:item.state}}</small></h2>',
          '{{/if}}',
          '{{if node}}',
          '<h3><i class="fa fa-lg {{>node_icon}}"></i> {{:node.name}} <small>{{:node.state}}</small></h3>',
          '{{/if}}'
        ].join('')
    };
    if (options === undefined) {
      options = defaults;
    } else {
      $.extend(defaults, options);
      options = defaults;
    }

    var colorByState = options.colors;

    var render = function(x, y, w, h, node, item) {
      var inset = 3;
      ctx.lineWidth = 3;
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

      if (hasFill && !hasStroke) {
        ctx.strokeStyle = ctx.fillStyle;
        ctx.strokeRect(x + inset, y + inset, w - inset*2, h - inset*2);
      }
      if (hasFill) {
        ctx.fillRect(x + inset, y + inset, w - inset*2, h - inset*2);
      }

      if (hasStroke && !hasFill) {
        ctx.fillStyle = ctx.strokeStyle;
        ctx.fillRect(x + inset, y + inset, w - inset*2, h - inset*2);
      }
      if (hasStroke) {
        ctx.strokeRect(x + inset, y + inset, w - inset*2, h - inset*2);
      }

      if (!hasStroke && !hasFill) {
        ctx.strokeStyle = options.colors.offline;
        ctx.strokeRect(x + inset, y + inset, w - inset*2, h - inset*2);
      }
    };


    var width = $(this).attr("width") || 320;
    var height = $(this).attr("height") || 240;
    var ncols = status.nodes.length + 1;
    var nrows = Math.max(status.resources.length + status.tickets.length, 1);
    var cellw = width / ncols;
    var cellh = height / nrows;

    var columns = [];
    for (var i = 0; i < status.nodes.length; ++i) {
      columns.push({name: status.nodes[i].name, state: status.nodes[i].state, row: []});
      columns[columns.length-1].row.length = nrows;
    }
    var stopped = {name: __("Stopped Resources"), state: null, row: []}
    columns.push(stopped);

    $.each(columns, function(col, node) {
      $.each(status.resources, function(row, rsc) {
        var hasInstance = false;
        if ("instances" in rsc) {
          for (var i = 0; i < rsc.instances.length; i++) {
            if (!hasInstance && rsc.instances[i].node == node.name) {
              hasInstance = true;
              var inst = {name: rsc.name, state: rsc.instances[i].state};
              node.row[row] = inst;
              render(col*cellw, row*cellh, cellw, cellh, node, inst);
            }
          }

          if (rsc.instances.length == 0 && !("_stopped" in rsc)) {
            rsc._stopped = true;
            var srsc = {name: rsc.name, state: "stopped"};
            stopped.row[row] = srsc;
            render((ncols-1)*cellw, row*cellh, cellw, cellh, stopped, srsc);
          }
        }
        if (!hasInstance) {
          render(col*cellw, row*cellh, cellw, cellh, node, null);
        }
      });
    });

    var toffset = status.resources.length;
    $.each(status.tickets, function(trow, ticket) {
      var row = trow + toffset;
      columns[0].row[row] = ticket;
      render(0*cellw, row*cellh, width, cellh, null, ticket);
    });

    var lasthitx = null;
    var lasthity = null;

    var infoTmpl = $.templates(options.info_template);

    this.on("mousemove", function(event) {
      var rx = event.pageX - $(this).offset().left;
      var ry = event.pageY - $(this).offset().top;
      var hitx = Math.floor(rx / cellw);
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
          $(options.info_selector).html(infoTmpl.render(data));
        }
      }
      lasthitx = hitx;
      lasthity = hity;
    }).on("mouseleave", function(event) {
      $(options.info_selector).css("display", "none");
    }).on("mouseenter", function(event) {
      $(options.info_selector).css("display", "block");
    });
  };
});
