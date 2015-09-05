// Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
// See COPYING for license.

$(function() {
  var make_error_handler = function(target, postfn) {
    return function(xhr, status, error) {
      console.log(xhr, status, error);
      var msg = error + " (" + xhr.status + ")";
      if ("responseJSON" in xhr && "error" in xhr.responseJSON) {
        msg += ": " + xhr.responseJSON.error;
      } else if ("responseText" in xhr) {
        msg += ": " + xhr.responseText;
      }
      target.html($('<div class="alert alert-danger"/>').html(msg));
      if (post !== undefined) {
        post(target);
      }
    };
  };

  $("#simulator-node").each(function() {
    var self = $(this);
    self.data("simulation-state", 0);
    self.html($("#simulator").render());

    var events = self.find("#sim-events");

    var update_events = function() {
      var delbtn = self.find("#sim-delete");
      if (events.find("option").length == 0) {
        delbtn.prop("disabled", "disabled");
      } else {
        delbtn.removeProp("disabled");
      }
    };
    update_events();

    var add_event = function(text, value) {
      events.append('<option value="' + value + '">' + text + '</option>');
      update_events();
    };

    var remove_selected_events = function() {
      events.find("option:selected").each(function() { $(this).remove(); });
      update_events();
    };

    var reset_simulation = function() {
      var $btn = $(this).button('loading');

      var data = {
        cib_id: $('body').data('cib')
      };

      self.find("#sim-results").attr("disabled", "disabled").removeClass("btn-success");

      var path = Routes.sim_reset_path();

      console.log("Reset:", path, data);

      $.ajax({
        type: "POST", dataType: "json", url: path, data: data,
        success: function(data) {
          events.find("option").each(function() { $(this).remove(); });
          update_events();
          $btn.button('reset');
        },
        error: make_error_handler(self.find(".errors"), function() {
          events.find("option").each(function() { $(this).remove(); });
          update_events();
          $btn.button('reset');
        })
      });
    };

    var run_simulation = function() {
      var $btn = $(this).button('loading');

      var data = {
        cib_id: $('body').data('cib'),
        injections: $.map(events.find("option").toArray(), function(opt) {
          return opt.value;
        })
      };

      var path = Routes.sim_run_path();

      console.log("Run:", path, data);

      $.ajax({
        type: "POST", dataType: "json", url: path, data: data,
        success: function(data) {
          self.find("#sim-results").removeAttr("disabled").addClass("btn-success");
          $btn.button('reset');
        },
        error: make_error_handler(self.find(".errors"), function() { $btn.button('reset'); })
      });
    };

    self.find("#sim-addnode").click(function() {
      var content = $("#modal .modal-content");
      content.html($("#inject-node").render());
      content.find("form").submit(function(event) {
        var name = content.find("#node-inject-node").val();
        var state = content.find("#node-inject-state").val();
        var val = ["node", name, state].join(" ");
        add_event(val, val);
        $("#modal").modal('hide');
        event.preventDefault();
      });
      $("#modal").modal('show');
    });

    self.find("#sim-addop").click(function() {
      var content = $("#modal .modal-content");
      content.html($("#inject-op").render());

      var set_op_defaults = function() {
        // set sensible default values for the given operation
        var rsc = content.find("#op-inject-rsc");
        var op = content.find("#op-inject-op");
        var interval = content.find("#op-inject-interval");

        interval.prop("disabled", "disabled");
        interval.val('');
        if (op.val() == "monitor") {
          var id = rsc.val().split(":")[0];

          interval.attr("placeholder", "fetching...");

          // get monitor intervals for resource
          $.getJSON(Routes.sim_intervals_path(id), "", function(data, status, xhr) {
            if (data.length >= 1) {
              interval.val(data[0]);
            }
            interval.removeProp("disabled").removeAttr("placeholder");
          });
        }
      };

      var set_res_defaults = function() {
        // This is to select the node the resource is currently running on, in
        // order that the user inject an op into the "right" place by default.
        var cib = $("body").data("content");
        var id_parts = content.find("#op-inject-rsc").val().split(":");
        var instance = cib.resources_by_id[id_parts[0]].instances[id_parts.length == 2 ? id_parts[1] : "default"];
        var running_on = instance.master || instance.slave || instance.started || instance.pending;
        if (running_on) {
          content.find("#op-inject-node").val(running_on[0].node);
        }
        set_op_defaults();
      };

      set_res_defaults();
      content.find("#op-inject-rsc").change(set_res_defaults);
      content.find("#op-inject-op").change(set_op_defaults);
      content.find("#op-inject-result").val(1);
      content.find("form").submit(function(event) {
        var rsc = content.find("#op-inject-rsc").val();
        var op = content.find("#op-inject-op").val();
        var interval = parseInt(content.find("#op-inject-interval").val());
        var node = content.find("#op-inject-node").val();
        var result = content.find("#op-inject-result").val();
        if (isNaN(interval))
          interval = 0;
        var val = ["op", op + ":" + interval, rsc, result, node].join(" ");
        add_event(val, val);
        $("#modal").modal('hide');
        event.preventDefault();
      });
      $("#modal").modal('show');
    });

    self.find("#sim-addticket").click(function() {
      $("#modal .modal-content").html($("#inject-ticket").render());
      content.find("form").submit(function(event) {
        var ticket = content.find("#ticket-inject-ticket").val();
        var action = content.find("#ticket-inject-action").val();
        var val = ["ticket", ticket, action].join(" ");
        add_event(val, val);
        $("#modal").modal('hide');
        event.preventDefault();
      });
      $("#modal").modal('show');
    });

    self.find("#sim-delete").click(remove_selected_events);

    self.find("#sim-reset").click(reset_simulation);

    self.find("#sim-run").click(run_simulation);


    self.find("#sim-results").click(function() {
      $("#modal-lg .modal-content").html($("#sim-results-dialog").render());

      var fetch_data = function(node, file) {
        $.ajax({
          url: Routes.sim_result_path(),
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
        $.ajax({
          url: Routes.sim_result_path(),
          type: "GET",
          data: {
            cib_id: $('body').data('cib'),
            file: file
          },
          success: function(data) {
            node.html($(data).find('svg'));
          },
          error: make_error_handler(node)
        });
      };

      fetch_data($("#modal-lg .sim-details"), 'info');
      fetch_data($("#modal-lg .sim-cib-in"), 'in');
      fetch_data($("#modal-lg .sim-cib-out"), 'out');
      fetch_data($("#modal-lg .sim-xml"), 'graph-xml');
      fetch_svg($("#modal-lg .sim-graph"), 'graph');


      $("#modal-lg").modal('show');
    });
  });
});
