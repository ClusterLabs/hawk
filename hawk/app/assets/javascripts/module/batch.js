// Copyright (c) 2016 Kristoffer Gronlund <kgronlund@suse.com>
// See COPYING for license.

$(function() {
  var make_error_handler = function(target, postfn) {
    return function(xhr, status, error) {
      var msg = error + " (" + xhr.status + ")";
      if ("responseJSON" in xhr && "error" in xhr.responseJSON) {
        msg += ": " + xhr.responseJSON.error;
      } else if ("responseText" in xhr) {
        msg += ": " + xhr.responseText;
      }
      target.html($('<div class="alert alert-danger"/>').html(msg));
      if (postfn !== undefined) {
        postfn(target);
      }
    };
  };

  var fetch_data = function(node, file) {
    $.ajax({
      url: Routes.sim_result_path(),
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      type: "GET",
      dataType: "text",
      data: {
        cib_id: $('body').data('cib'),
        file: file
      },
      success: function(data) {
        var code = "";
        if (file == "graph-xml" || file == "in" || file == "out") {
          code = '<pre><code class="xml hljs">';
          code += $('<div/>').text(data).html();
          code += '</code></pre>';
        } else if (file == "diff") {
          if (data) {
            code = '<pre><code class="crmsh hljs">';
            code += $('<div/>').text(data).html();
            code += '</code></pre>';
          } else {
            code = '<div class="text-muted text-center">';
            code += __("No configuration changes.");
            code += '</div>';
          }
        } else {
          code = '<pre>';
          code += data;
          code += '</pre>';
        }
        node.html(code);

        node.find('.hljs').each(function(i, block) {
          hljs.highlightBlock(block);
        });
      },
      error: make_error_handler(node)
    });
  };

  var fetch_svg = function(node, file) {
    url = Routes.sim_result_path() + "?cib_id=" + encodeURIComponent($('body').data('cib')) + "&file=" + encodeURIComponent(file) + "&_ts=" + Date.now();
    node.html('<a href="' + url + '" target="_blank"><img src="' + url + '"></a>');
  };

  function run_simulation() {
    var events_data = null;
    var events = $('#batch-view #batch-entries .list-group');
    if (events) {
      events_data = $.map(events.find("li").toArray(), function(entry) {
        return $(entry).data('entry');
      });
      Cookies.set("hawk-batch-events", events_data);
    } else {
      events_data = Cookies.getJSON('hawk-batch-events');
      if (!events_data) {
        events_data = [];
      }
    }

    var data = {
      cib_id: $('body').data('cib'),
      injections: events_data
    };

    var path = Routes.sim_run_path();

    var dialog = $("#modal-lg .modal-content #batch-view");

    $.ajax({
      type: "POST", dataType: "json", url: path, data: data,
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      success: function(data) {
        $.updateCib();

        if (dialog) {
          fetch_data($(".batch-diff-data"), 'diff');
        }
      },
      error: function(xhr, status, error) {
        if (dialog) {
          var msg = error + " (" + xhr.status + ")";
          dialog.find(".errors").html($('<div class="alert alert-danger"/>').html(msg));
        }
        $.updateCib();
      }
    });
  };

  $('body').on('hawk.run.simulator', function() {
    run_simulation();
  });

  $(".batch-control-bar").each(function() {
    var self = $(this);

    self.find("#btn-show-batch").click(function() {
      var content = $("#modal-lg .modal-content");
      content.html($("#batch-template").render());

      content.find('a[href="#batch-view"]').on('shown.bs.tab', function (e) {
        content.find('li.active').removeClass("active");
      });

      var events = content.find('#batch-entries .list-group');

      function add_event(e) {
        events.append($("#batch-entry").render({ name: e, value: e }));
        events.find("li:last a").on("click", function(e) {
          e.preventDefault();
          $(this).closest("li").remove();
          run_simulation();
        });
        run_simulation();
      };

      // load events from cookie (if any)
      (function() {
        var stored_events = Cookies.getJSON('hawk-batch-events');
        if (stored_events !== undefined && stored_events !== null) {
          $.each(stored_events, function(i, e) {
            events.append($("#batch-entry").render({ name: e, value: e }));
          });
          events.find("li").on("click", function(e) {
            e.preventDefault();
            $(this).closest("li").remove();
            run_simulation();
          });
        }
        run_simulation();
      }());

      content.find('a[href="#batch-summary"]').on('shown.bs.tab', function (e) {
        fetch_data($(".batch-summary-data"), 'info');
      });

      content.find('a[href="#batch-cib-in"]').on('shown.bs.tab', function (e) {
        fetch_data($(".batch-cib-in-data"), 'in');
      });

      content.find('a[href="#batch-cib-out"]').on('shown.bs.tab', function (e) {
        fetch_data($(".batch-cib-out-data"), 'out');
      });

      content.find('a[href="#batch-transition"]').on('shown.bs.tab', function (e) {
        fetch_data($(".batch-transition-data"), 'graph-xml');
      });

      content.find('a[href="#batch-transition-graph"]').on('shown.bs.tab', function (e) {
        fetch_svg($(".batch-transition-graph-data"), 'graph');
      });

      content.find('#batch-node-event .modal-footer .btn-primary').on('click', function(e) {
        var name = content.find("#node-inject-node").val();
        var state = content.find("#node-inject-state").val();
        var val = ["node", name, state].join(" ");
        add_event(val, val);
      });

      content.find('#batch-resource-event .modal-footer .btn-primary').on('click', function(e) {
        var rsc = content.find("#op-inject-rsc").val();
        var op = content.find("#op-inject-op").val();
        var interval = parseInt(content.find("#op-inject-interval").val());
        var node = content.find("#op-inject-node").val();
        var result = content.find("#op-inject-result").val();
        if (isNaN(interval))
          interval = 0;
        var val = ["op", op + ":" + interval, rsc, result, node].join(" ");
        add_event(val, val);
      });

      content.find('#batch-ticket-event .modal-footer .btn-primary').on('click', function(e) {
        var ticket = content.find("#ticket-inject-ticket").val();
        var action = content.find("#ticket-inject-action").val();
        var val = ["ticket", ticket, action].join(" ");
        add_event(val, val);
      });

      $("#modal-lg").modal('show');
    });
  });

  $.fn.fetchShadowCIBDiff = function() {
    return fetch_data($(this), 'diff');
  };
});
