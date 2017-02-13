// Copyright (c) 2016 Kristoffer Gronlund <kgronlund@suse.com>
// See COPYING for license.

$(function() {
  $('[data-fencingeditor]').each(function() {
    var uuidInc = [0];
    var element = $(this);
    var content = $('body').data('content');
    var leveltemplate = $.templates('#fencing-level-template');
    var body = '<ul id="fencing-level-list" class="list-unstyled">';
    var editor = {
      uuid: 0,
      topology: $.extend(true, [], content.fencing_topology)
    };

    window.debugHandleFencingEditor = editor;

    function renderLevel(idx, level) {
      if (level.type == "node") {
        level._typename = __("Node");
      } else if (level.type == "pattern") {
        level._typename = __("Pattern");
      } else if (level.type == "attribute") {
        level._typename = __("Attribute");
      }
      level._id = "level-" + editor.uuid;
      editor.uuid = editor.uuid + 1;
      level._sort_index = idx;
      level._up = idx > 0;
      level._down = idx < editor.topology.length-1;
      return leveltemplate.render(level);
    }

    $.each(editor.topology, function(idx, level) {
      body += renderLevel(idx, level);
    });
    body += "</ul>";
    var controlstemplate = $.templates('#fencing-controls-template');
    body += controlstemplate.render({});
    element.html(body);

    function allowApply(enable) {
      if (enable) {
        element.find('#fl-apply').removeAttr('disabled');
      } else {
        element.find('#fl-apply').attr('disabled', true);
      }
    }

    function fixupPostChange() {
      element.find('.fencing-level').each(function(index) {
        $(this).data('sort-index', index);
        editor.topology[index]._up = index > 0;
        editor.topology[index]._down = index < editor.topology.length - 1;
        if (editor.topology[index]._up) {
          $(this).find('#fl-up').removeAttr('disabled');
        } else {
          $(this).find('#fl-up').attr('disabled', true);
        }
        if (editor.topology[index]._down) {
          $(this).find('#fl-down').removeAttr('disabled');
        } else {
          $(this).find('#fl-down').attr('disabled', true);
        }
      });
      allowApply(true);
    }

    function renderLevels() {
      // the number of levels is the same
      // but the order has changed. We can
      // just re-copy values from the backing store
      // into the DOM.
      editor.uuid = 0;
      element.find('#fencing-level-list').html($.map(editor.topology, function(level, idx) {
        return renderLevel(idx, level);
      }).join(""));
    }

    function validate() {
      var errors = [];
      function err(idx, msg) {
        errors.push(__("Level") + " #" + idx + ": " + msg);
      }
      $.each(editor.topology, function(idx, level) {
        if (!level.target) {
          err(idx, __("Expected target"));
        }
        if (level.type == "attribute" && !level.value) {
          err(idx, __("Expected value for attribute"));
        }
        if (level.index < 0) {
          err(idx, __("Expected non-negative index"));
        }
        $.each(level.devices, function(_, dev) {
          var isFencingDevice = false;
          var isResource = false;
          $.each(content.resources, function(_, rsc) {
            if (dev == rsc.id) {
              isResource = true;
              if (rsc["class"] == "stonith") {
                isFencingDevice = true;
              }
            }
          });
          if (isResource && !isFencingDevice) {
            err(idx, i18n.translate("%s is not a fencing device").fetch(dev));
          } else if (!isResource) {
            err(idx, i18n.translate("fencing device %s not found").fetch(dev));
          }
        });
      });
      return errors;
    }

    function submit() {
      function clean_topology() {
        return $.map(editor.topology, function(item) {
          return {
            type: item.type,
            target: item.target,
            value: item.value,
            index: item.index,
            devices: item.devices
          };
        });
      }
      $.ajax({
        type: "POST",
        url: Routes.cib_fencing_edit_path($('body').data('cib')),
        data: JSON.stringify({ fencing: clean_topology() }),
        dataType: "json",
        contentType: "application/json",
        success: function() {
          allowApply(false);
          $.growl({
            message: __("Changes applied successfully.")
          },{
            type: 'success'
          });
        },
        error: function(xhr, status, msg) {
          $.growl({
            message: xhr.responseText || msg
          },{
            type: 'danger'
          });
        }
      });
    }

    element.on('click', '#fl-up', function(e) {
      e.preventDefault();
      var ilevel = $(this).closest('.fencing-level').data('sort-index');
      var item = editor.topology[ilevel];
      editor.topology.splice(ilevel, 1)
      editor.topology.splice(ilevel-1, 0, item);
      renderLevels();
      allowApply(true);
    }).on('click', '#fl-down', function(e) {
      e.preventDefault();
      var ilevel = $(this).closest('.fencing-level').data('sort-index');
      var item = editor.topology[ilevel];
      editor.topology.splice(ilevel, 1)
      editor.topology.splice(ilevel+1, 0, item);
      renderLevels();
      allowApply(true);
    }).on('click', '#fl-delete', function(e) {
      e.preventDefault();
      var self = $(this).closest('.fencing-level');
      $.hawkAsyncConfirm(__('Are you sure you wish to delete this level?'), function() {
        var ilevel = self.data('sort-index');
        editor.topology.splice(ilevel, 1);
        self.remove();
        fixupPostChange();
      });
    }).on('click', '#fl-sel-node', function(e) {
      var ilevel = $(this).closest('.fencing-level').data('sort-index');
      editor.topology[ilevel].type = "node";
      renderLevels();
      allowApply(true);
    }).on('click', '#fl-sel-pattern', function(e) {
      var ilevel = $(this).closest('.fencing-level').data('sort-index');
      editor.topology[ilevel].type = "pattern";
      renderLevels();
      allowApply(true);
    }).on('click', '#fl-sel-attribute', function(e) {
      var ilevel = $(this).closest('.fencing-level').data('sort-index');
      editor.topology[ilevel].type = "attribute";
      renderLevels();
      allowApply(true);
    }).on('change', '#fl-target', function(e) {
      var ilevel = $(this).closest('.fencing-level').data('sort-index');
      editor.topology[ilevel].target = $(this).val();
      allowApply(true);
    }).on('change', '#fl-value', function(e) {
      var ilevel = $(this).closest('.fencing-level').data('sort-index');
      editor.topology[ilevel].value = $(this).val();
      allowApply(true);
    }).on('change', '#fl-index', function(e) {
      var ilevel = $(this).closest('.fencing-level').data('sort-index');
      editor.topology[ilevel].index = parseInt($(this).val());
      allowApply(true);
    }).on('change', '#fl-devices', function(e) {
      var ilevel = $(this).closest('.fencing-level').data('sort-index');
      editor.topology[ilevel].devices = $(this).val().split(/[\s,]+/);
      allowApply(true);
    }).on('click', '#fl-add-level', function(e) {
      var newindex = editor.topology.length;
      var newitem = {
        type: "node",
        target: "",
        value: null,
        index: 1,
        devices: [],
      };
      editor.topology.push(newitem);
      element.find('#fencing-level-list').append(renderLevel(newindex, newitem));
      fixupPostChange();
    }).on('click', '#fl-apply', function(e) {
      var errors = validate();
      if (errors.length == 0) {
        submit();
      } else {
        $.each(errors, function(_, err) {
          $.growl({ message: err }, { type: 'danger' });
        });
      }
    });
  });
});
