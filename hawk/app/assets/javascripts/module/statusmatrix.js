// Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
// See COPYING for license.

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
        unclean: "#ec008c",
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
        unclean: "fa-circle text-danger",
        granted: "fa-check-circle text-success",
        revoked: "fa-times-circle-o text-muted",
        elsewhere: "fa-question-circle text-warning",
      },
      title: __("Details"),
      info_selector: "#cib-status-matrix-details",
      info_template: [
        '<ul class="list-unstyled">',
        '{{if item}}',
        '<li><h3><i class="fa fa-lg {{>item_icon}}"></i> {{:item.name}} <small>{{:item.state}}</small></h3></li>',
        '{{/if}}',
        '{{if node}}',
        '<li><h3><i class="fa fa-lg {{>node_icon}}"></i> {{:node.name}} <small>{{:node.state}}</small></h3></li>',
        '{{/if}}',
        '</ul>'
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
    var hasremotes = false;
    for (var i = 0; i < status.nodes.length; ++i) {
      if (status.nodes[i].remote) {
        hasremotes = true;
        columns.push({name: status.nodes[i].name, state: status.nodes[i].state, remote: true, row: []});
        columns[columns.length-1].row.length = nrows;
      }
    }
    var totalspacings = 10;
    if (hasremotes) {
      totalspacings += 10;
    }
    var cellw = (width - totalspacings) / ncols;
    var cellh = height / nrows;
    var stopped = {name: __("Stopped Resources"), remote: false, state: null, row: []}
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
          var abshitx = $(this).offset().left + hitx*cellw;
          var abshity = $(this).offset().top + hity*cellh;
          var target = $(options.info_selector);
          target.html(infoTmpl.render(data)).width("auto");
          if (abshitx + (cellw / 2) > $(window).width() / 2) {
            target.addClass("right").removeClass("left").offset({left: abshitx - 16 - target.outerWidth(), top: abshity - 16});
          } else {
            target.removeClass("right").addClass("left").offset({left: abshitx + cellw + 16, top: abshity - 16});
          }
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
