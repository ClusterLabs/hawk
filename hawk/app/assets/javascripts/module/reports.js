// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  var time_format_string = 'YYYY-MM-DD H:mm';

  var build_running = function(start, end) {
    $('#reports #report-running').removeClass('hidden');
    $('#reports #report-tabs').addClass('hidden');
  };

  var running_timeout = null;

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
          $.growl({
            message: __("Report generation is complete.")
          },{
            type: 'success'
          });
          $('#reports #middle table.reports').bootstrapTable('refresh');
          build_tabs();
        }
      });
    }, 5000);
  };

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
        showColumns: true,
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
            if (value.slice(0, 5) == "hawk-") {
              return "hawk";
            } else {
              return value;
            }
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

              try {
                answer = confirm(
                  i18n.translate(
                    'Are you sure you wish to delete %s?'
                  ).fetch(row.name)
                );
              } catch (e) {
                (console.error || console.log).call(console, e.stack || e);
              }

              if (answer) {
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
              }
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


  $('#reports #report-show').each(function() {
    $(this).find('.remote a[data-toggle="tab"]')
      .on('show.bs.tab', function(e) {
        var hash = this.hash;
        var target = $(e.target);

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

    $(this).find('.remote li.active a[data-toggle="tab"]').each(function(index, link) {
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
  });
});
