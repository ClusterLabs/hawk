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
