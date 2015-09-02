// Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
// See COPYING for license.

$(function() {
  $("#simulator-node").each(function() {
    var cibModal = function() {
    };

    var nodeInjectModal = function() {
    };

    $(this).html($("#simulator").render());
    $(this).find("#sim-addnode").click(function() {
      $("#modal .modal-content").html($("#inject-node").render());
      $("#modal").modal('show');
    });
    $(this).find("#sim-addop").click(function() {
      $("#modal .modal-content").html($("#inject-op").render());
      $("#modal").modal('show');
    });
  });
});
