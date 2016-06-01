// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  var time_format_string = 'YYYY-MM-DD HH:mm Z';
  var REFRESH_INTERVAL = 5000;
  var running_timeout = null;

  var build_running = function(start, end) {
    $('#reports #running-from-time').val(moment(start).format(time_format_string));
    $('#reports #running-to-time').val(moment(end).format(time_format_string));
    $('#reports #report-running').removeClass('hidden');
    $('#reports #report-tabs').addClass('hidden');
  };

  var start_running_refresh = function() {
    if (running_timeout !== null) {
      clearInterval(running_timeout);
      running_timeout = null;
    }
    running_timeout = setInterval(function() {
      $.getJSON(Routes.running_reports_path(), {}, function(state) {
        if (state.running) {
          // repeat...
        } else {
          if (running_timeout !== null) {
            clearInterval(running_timeout);
            running_timeout = null;
          }
          $.growl({ message: __("Report generation is complete.") }, { type: 'success' });
          $('#reports #middle table.reports').bootstrapTable('refresh');
          build_tabs();
        }
      });
    }, REFRESH_INTERVAL);
  };

  $('#reports #report-running').on('click', '#cancel-report', function() {
    $.getJSON(Routes.cancel_reports_path(), {}, function(data) {
      if (data.error) {
        $.growl({ message: data.error },{ type: 'danger' });
      } else {
        if (running_timeout !== null) {
          clearInterval(running_timeout);
          running_timeout = null;
        }
        $.growl({ message: __("Report generation cancelled.") },{ type: 'danger' });
        $('#reports #middle table.reports').bootstrapTable('refresh');
        build_tabs();
      }
    });
  });


  var build_tabs = function() {
    $('#reports #report-running').addClass('hidden');
    $('#reports #report-tabs').removeClass('hidden');

    var controls = $("#reports #report-controls");

    controls.find('.uploadfield')
      .fileinput({
        uploadUrl: Routes.upload_reports_path({
          format: 'json'
        }),

        uploadAsync: true,
        showPreview: false,
        dropZoneEnabled: false,
        allowedFileExtensions: ['gz', 'bz2', 'xz'],
        minFileCount: 1,

        browseIcon: '<i class="fa fa-folder-open"></i> ',
        removeIcon: '<i class="fa fa-trash"></i> ',
        cancelIcon: '<i class="fa fa-ban-circle"></i> ',
        uploadIcon: '<i class="fa fa-upload"></i> '
      })
      .on('filebatchuploadsuccess', function(e, data) {
        if (data.response.success) {
          $.growl({
            message: data.response.message
          },{
            type: 'success'
          });
        } else {
          $.growl({
            message: data.response.message
          },{
            type: 'warning'
          });
        }

        $('#reports #middle table.reports').bootstrapTable('refresh');
      })
      .on('filebatchuploaderror', function(e, data) {
        $.growl({
          message: data.response.error
        },{
          type: 'danger'
        });
      });

    var now = moment();
    var one_hour_ago = now.clone().subtract(1, 'hour');

    // update the display format immediately
    var update_selected_daterange = function(start, end) {
      controls.find('.rangefield .current')
        .html(start.format(time_format_string) + ' - ' + end.format(time_format_string));
      controls.find('form.generate')
        .find('#report_from_time')
        .val(start.toISOString())
        .end()
        .find('#report_to_time')
        .val(end.toISOString())
        .end();
    };

    controls.find('.rangefield')
      .daterangepicker({
        format: time_format_string,
        startDate: one_hour_ago,
        endDate: now,
        maxDate: now.clone().endOf('month').endOf('day'),

        showDropdowns: true,
        showWeekNumbers: true,
        timePicker: true,
        timePickerIncrement: 1,
        timePicker12Hour: false,

        applyClass: 'btn-primary',
        cancelClass: 'btn-default',
        buttonClasses: [
          'btn',
          'btn-sm'
        ],

        ranges: {
          'Last Hour': [
            one_hour_ago,
            now
          ],
          'Last 6 Hours': [
            now.clone().subtract(6, 'hours'),
            now
          ],
          'Today': [
            now.clone().startOf('day'),
            now.clone().endOf('day')
          ],
          'Yesterday': [
            now.clone().subtract(1, 'days').startOf('day'),
            now.clone().subtract(1, 'days').endOf('day')
          ],
          'Last 7 Days': [
            now.clone().subtract(6, 'days').startOf('day'),
            now.clone().endOf('day')
          ],
          'This Month': [
            now.clone().startOf('month').startOf('day'),
            now.clone().endOf('month').endOf('day')
          ]
        },
        locale: {
          firstDay: 1,
          applyLabel: __('Apply'),
          cancelLabel: __('Cancel'),
          fromLabel: __('From'),
          toLabel: __('Until'),
          customRangeLabel: __('Custom'),
          daysOfWeek: [
            __('Su'),
            __('Mo'),
            __('Tu'),
            __('We'),
            __('Th'),
            __('Fr'),
            __('Sa')
          ],
          monthNames: [
            __('January'),
            __('February'),
            __('March'),
            __('April'),
            __('May'),
            __('June'),
            __('July'),
            __('August'),
            __('September'),
            __('October'),
            __('November'),
            __('December')
          ]
        }
      }, function(start, end, label) {
        update_selected_daterange(start, end);
      });

    update_selected_daterange(one_hour_ago, now);

    controls.find('form.generate')
      .on('ajax:before', function() {
        var from_ = controls.find('form.generate #report_from_time').val();
        var to_ = controls.find('form.generate #report_to_time').val();
        build_running(from_, to_);
      })
      .on('ajax:success', function(data, response, xhr) {
        if ("error" in response) {
          build_tabs();
          $.growl({
            message: response.error
          },{
            type: 'danger'
          });
        } else {
          start_running_refresh();
          $.growl({
            message: response.message
          },{
            type: 'success'
          });
        }
      })
      .on('ajax:error', function(xhr, status, msg) {
        build_tabs();

        $.growl({
          message: xhr.responseJSON.error || msg
        },{
          type: 'danger'
        });
      });
  };

  var running_state_refreshed = function(status) {
    if (status.running) {
      build_running(status.time[0], status.time[1]);
      start_running_refresh();
    } else {
      build_tabs();
    }
  };

  $('#reports #report-index').each(function() {
    $.getJSON(Routes.running_reports_path(), {}, running_state_refreshed);

    $('#reports #middle table.reports')
      .bootstrapTable({
        method: 'get',
        url: Routes.reports_path(
          { format: 'json' }
        ),
        striped: true,
        pagination: true,
        pageSize: 50,
        pageList: [10, 25, 50, 100, 200],
        sidePagination: 'client',
        smartDisplay: false,
        search: true,
        searchAlign: 'left',
        showColumns: false,
        showRefresh: true,
        minimumCountColumns: 0,
        sortName: 'to_time',
        sortOrder: 'desc',
        columns: [{
          field: 'name',
          title: __('Name'),
          sortable: true,
          switchable: false,
          clickToSelect: true,
          formatter: function(value, row, index) {
            var title = value;
            if (value.slice(0, 5) == "hawk-")
              title = "hawk";
            return ['<a href="', Routes.report_path(row.id), '" title="', __('Show'), '">', title, '</a> '].join("");
          }
        },{
          field: 'from_time',
          title: __('From'),
          sortable: true,
          switchable: false,
          clickToSelect: true,
          formatter: function(value, row, index) {
            if (moment(row.from_time).isSame(row.to_time)) {
              return "";
            } else {
              return moment(value).format(time_format_string);
            }
          }
        }, {
          field: 'to_time',
          title: __('Until'),
          sortable: true,
          switchable: false,
          clickToSelect: true,
          formatter: function(value, row, index) {
            return moment(value).format(time_format_string);
          }
        }, {
          field: 'operate',
          title: __('Operations'),
          sortable: false,
          clickToSelect: false,
          class: 'col-sm-2',
          events: {
            'click .delete': function (e, value, row, index) {
              e.preventDefault();
              var $self = $(this);

              $.hawkAsyncConfirm(i18n.translate('Are you sure you wish to delete %s?').fetch(row.name), function() {
                $.ajax({
                  dataType: 'json',
                  method: 'POST',
                  data: {
                    _method: 'delete'
                  },
                  url: Routes.report_path(
                    row.id,
                    { format: 'json' }
                  ),

                  success: function(data) {
                    if (data.success) {
                      $.growl({
                        message: data.message
                      },{
                        type: 'success'
                      });

                      $self.parents('table').bootstrapTable('refresh')
                    } else {
                      if (data.error) {
                        $.growl({
                          message: data.error
                        },{
                          type: 'danger'
                        });
                      }
                    }
                  },
                  error: function(xhr, status, msg) {
                    $.growl({
                      message: xhr.responseJSON.error || msg
                    },{
                      type: 'danger'
                    });
                  }
                });
              });
            }
          },
          formatter: function(value, row, index) {
            var operations = []

            operations.push([
              '<a href="',
              Routes.report_path(row.id),
              '" class="show btn btn-success btn-xs" title="',
              __('Show'),
              '">',
              '<i class="fa fa-search"></i>',
              '</a> '
            ].join(''));

            operations.push([
              '<a href="',
              Routes.download_report_path(row.id),
              '" class="download btn btn-info btn-xs" title="',
              __('Download'),
              '" download>',
              '<i class="fa fa-download"></i>',
              '</a> '
            ].join(''));

            operations.push([
              '<a href="',
              Routes.report_path(
                row.id
              ),
              '" class="delete btn btn-danger btn-xs" title="',
              __('Delete'),
              '">',
              '<i class="fa fa-trash"></i>',
              '</a> '
            ].join(''));

            return [
              '<div class="btn-group" role="group">',
              operations.join(''),
              '</div>',
            ].join('');
          }
        }]
      });
  });

  function afterDisplay(self) {
    var data = $('#reports #transition-data');
    var report = data.data('report');
    var transitions = $.parseJSON(data.text());

    $.each(transitions, function(i, item) {
      item.index = i;
    });

    var last_popover_element = null;

    $('#reports #eventcontrol').EventControl({
      data: transitions,
      onhover: function(item, element, event, inout) {
        if (inout == 'in') {
          element.data('title', item.basename);
          element.data('content', [
            "<dl>",
            "<dt>", __("Time"),  "</dt>",
            "<dd>", moment(item.timestamp).format(time_format_string),  "</dd>",
            "<dt>", __("Node"),  "</dt>",
            "<dd>", item.node,  "</dd>",
            "</dl>"
          ].join(""));

          if (last_popover_element != element) {
            if (last_popover_element != null) {
              last_popover_element.popover('destroy');
            }
            element.popover({
              placement: 'top',
              container: 'body',
              html: true
            });
            last_popover_element = element;
          }
          element.popover('show');
        } else {
          element.popover('hide');
        }
      },
      oncreate: function(item, element) {
        if (parseInt($.urlParam('transition')) == item.index + 1) {
          element.css('color', '#94FB23');
        } else if (item.basename.indexOf('error') > -1) {
          element.addClass('text-danger');
        } else if (item.basename.indexOf('warn') > -1) {
          element.addClass('text-warning');
        } else if (item.basename.indexOf('input') > -1) {
          element.addClass('text-info');
        }
      },
      onclick: function(item, element, event) {
        Cookies.set("hawk-eventcontrol", {report: report, state: this.save_state()});
        var hash = location.hash;
        if (!hash) {
          hash = '';
        }
        location.href = Routes.display_report_path(report, {transition: item.index + 1}) + hash;
      },
    });

    $('#reports #middle .zoom-in').on('click', function() {
      $('#reports #eventcontrol').EventControl('zoom-in');
    });

    $('#reports #middle .zoom-out').on('click', function() {
      $('#reports #eventcontrol').EventControl('zoom-out');
    });

    $('#reports #middle .panel-heading .btn-primary').each(function(index, link) {
          var a = $(link)
          a.attr('href', a.attr('href').split('#')[0] + location.hash);
    });

    var state = Cookies.getJSON('hawk-eventcontrol');
    if (state && "report" in state && "state" in state && state.report == report) {
      $('#reports #eventcontrol').EventControl(state.state);
    }

    self.find('.dropdown-toggle').dropdown();

    self.find('.remote a[data-toggle="tab"]')
      .on('show.bs.tab', function(e) {
        var hash = this.hash;
        var target = $(e.target);

        $('#reports #middle .panel-heading .btn-primary').each(function(index, link) {
          var $link = $(link)

          $link.attr(
            'href',
            $link.attr('href').split('#')[0] + hash
          );
        });

        if (target.hasClass("loaded")) {
          return true;
        }

        $.ajax({
          url: target.data('url'),
          success: function(data) {
            if (data) {
              if (!target.hasClass("loaded")) {
                target.addClass("loaded");
              }

              $(hash).html(data);
              $(hash).find('.hljs').each(function(i, block) {
                hljs.highlightBlock(block);
              });
            }
          },
          fail: function(data) {
            $.growl({
              message: data.response.error
            },{
              type: 'danger'
            });
          }
        });
      });

    self.find('.remote li.active a[data-toggle="tab"]').each(function(index, link) {
      var hash = this.hash;
      var target = $(link);

      $('#reports #middle .iterator a').each(function(index, link) {
        var $link = $(link)

        $link.attr(
          'href',
          $link.attr('href').split('#')[0] + hash
        );
      });

      if (target.hasClass("loaded")) {
        return true;
      }

      $.ajax({
        url: target.data('url'),
        success: function(data) {
          if (data) {
            if (!target.hasClass("loaded")) {
              target.addClass("loaded");
            }

            $(hash).html(data);

            $(hash).find('.hljs').each(function(i, block) {
              hljs.highlightBlock(block);
            });
          }
        },
        fail: function(data) {
          $.growl({
            message: data.response.error
          },{
            type: 'danger'
          });
        }
      });
    });
  }

  $('#reports #report-show').each(function() {
    var report_id = $(this).data('report');
    $(this).find('#cancel-report-loading').on('click', function(e) {
      location.href = Routes.reports_path();
    });
    $.ajax({
      url: Routes.display_report_path({id: report_id}),
      dataType: "html",
      success: function(data) {
        $('#reports #report-show').replaceWith(data);
        afterDisplay($('#reports #report-display'));
      }
    });
  });

  $('#reports #report-display').each(function() {
    afterDisplay($(this));
  });
});
