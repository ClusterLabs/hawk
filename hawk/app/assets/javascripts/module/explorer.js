// Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
// See COPYING for license.

$(function() {
  $('#explorers #middle .uploadfield')
    .fileinput({
      uploadUrl: Routes.upload_explorers_path({
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

      $('#explorers #middle table.explorers')
        .bootstrapTable('refresh');
    })
    .on('filebatchuploaderror', function(e, data) {
      $.growl({
        message: data.response.error
      },{
        type: 'danger'
      });
    });

  $('#explorers #middle .rangefield')
    .daterangepicker({
      format: 'MM/DD/YYYY HH:mm',
      startDate: moment().subtract(1, 'hour'),
      endDate: moment(),
      maxDate: moment().endOf('month').endOf('day'),

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
        'Today': [
          moment().startOf('day'),
          moment().endOf('day')
        ],
        'Yesterday': [
          moment().subtract(1, 'days').startOf('day'),
          moment().subtract(1, 'days').endOf('day')
        ],
        'Last 7 Days': [
          moment().subtract(6, 'days').startOf('day'),
          moment().endOf('day')
        ],
        'Last 30 Days': [
          moment().subtract(29, 'days').startOf('day'),
          moment().endOf('day')
        ],
        'This Month': [
          moment().startOf('month').startOf('day'),
          moment().endOf('month').endOf('day')
        ],
        'Last Month': [
          moment().subtract(1, 'month').startOf('month').startOf('day'),
          moment().subtract(1, 'month').endOf('month').endOf('day')
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
      $('#explorers #middle .rangefield .current').html(
        start.format('MMMM D, YYYY HH:mm') + ' - ' + end.format('MMMM D, YYYY HH:mm')
      );

      $('#explorers #middle form.search')
        .find('.from')
          .val(start.format('MMMM D, YYYY HH:mm'))
          .end()
        .find('.until')
          .val(end.format('MMMM D, YYYY HH:mm'))
          .end();
    });

  $('#explorers #middle form.generate')
    .on('ajax:before', function() {
      $.blockUI({
        message: [
          '<i class="fa fa-spinner fa-pulse fa-3x"></i>',
          '<br/>',
          '<h1>',
            __('Generating report...'),
          '</h1>'
        ].join('')
      });
    })
    .on('ajax:success', function(data, response, xhr) {
      $.unblockUI();

      if (response.success) {
        $.growl({
          message: response.message
        },{
          type: 'success'
        });
      } else {
        $.growl({
          message: response.message
        },{
          type: 'warning'
        });
      }

      $('#explorers #middle table.explorers')
        .bootstrapTable('refresh');
    })
    .on('ajax:error', function(xhr, status, msg) {
      $.unblockUI();

      $.growl({
        message: xhr.responseJSON.error || msg
      },{
        type: 'danger'
      });
    });

  $('#explorers #middle table.explorers')
    .bootstrapTable({
      method: 'get',
      url: Routes.explorers_path(
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
      sortName: 'from',
      sortOrder: 'asc',
      columns: [{
        field: 'from',
        title: __('From'),
        sortable: true,
        switchable: false,
        clickToSelect: true
      }, {
        field: 'until',
        title: __('Until'),
        sortable: true,
        switchable: false,
        clickToSelect: true
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
                  'Are you sure you wish to delete %s - %s?'
                ).fetch(row.from, row.until)
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
                url: Routes.explorer_path(
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
                Routes.show_explorer_path(
                  row.id,
                  1
                ),
              '" class="show btn btn-default btn-xs" title="',
              __('Show'),
            '">',
              '<i class="fa fa-search"></i>',
            '</a> '
          ].join(''));

          operations.push([
            '<a href="',
                Routes.explorer_path(
                  row.id
                ),
              '" class="delete btn btn-default btn-xs" title="',
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

  $('#explorers #middle .remote a[data-toggle="tab"]')
    .on('show.bs.tab', function(e) {
      var hash = this.hash;
      var target = $(e.target);

      $('#explorers #middle .iterator a').each(function(index, link) {
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

  $('#explorers #middle .remote li.active a[data-toggle="tab"]').each(function(index, link) {
    var hash = this.hash;
    var target = $(link);

    $('#explorers #middle .iterator a').each(function(index, link) {
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
