// Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
// See COPYING for license.

$(function() {
  $("#simulator-node").each(function() {
    var self = $(this);
    self.data("simulation-state", 0);
    self.html($("#simulator").render());

    var events = self.find("#sim-events");

    var update_events = function() {
      var delbtn = self.find("#sim-delete");
      var runbtn = self.find("#sim-run");
      if (events.find("option").length == 0) {
        delbtn.prop("disabled", "disabled");
        runbtn.prop("disabled", "disabled");
      } else {
        delbtn.removeProp("disabled");
        runbtn.removeProp("disabled");
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

    var remove_all_events = function() {
      events.find("option").each(function() { $(this).remove(); });
      update_events();
    };

    var run_events = function() {
      console.log("Run simulation...");
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
        var interval = content.find("#op-inject-interval").val();
        var node = content.find("#op-inject-node").val();
        var result = content.find("#op-inject-result").val();
        if (isNaN(interval) || interval == "" || interval == null)
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

    self.find("#sim-reset").click(remove_all_events);

    self.find("#sim-run").click(run_events);
  });
});
