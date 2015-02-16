//======================================================================
//                        HA Web Konsole (Hawk)
// --------------------------------------------------------------------
//            A web-based GUI for managing and monitoring the
//          Pacemaker High-Availability cluster resource manager
//
// Copyright (c) 2009-2013 SUSE LLC, All Rights Reserved.
//
// Author: Tim Serong <tserong@suse.com>
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of version 2 of the GNU General Public License as
// published by the Free Software Foundation.
//
// This program is distributed in the hope that it would be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//
// Further, this software is distributed without any warranty that it is
// free of the rightful claim of any third person regarding infringement
// or the like.  Any license provided herein, whether implied or
// otherwise, applies only to this software file.  Patent licenses, if
// any, provided herein do not apply to combinations of this program with
// other software, or any other product whatsoever.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write the Free Software Foundation,
// Inc., 59 Temple Place - Suite 330, Boston MA 02111-1307, USA.
//
//======================================================================

$(function() {
  // $('#dashboards #content table.nodes')
  //   .bootstrapTable({
  //     method: 'get',
  //     url: Routes.cib_nodes_path(
  //       $('body').data('cib'),
  //       { format: 'json' }
  //     ),
  //     striped: true,
  //     pagination: true,
  //     pageSize: 50,
  //     pageList: [10, 25, 50, 100, 200],
  //     sidePagination: 'client',
  //     smartDisplay: false,
  //     search: true,
  //     searchAlign: 'left',
  //     showColumns: true,
  //     showRefresh: true,
  //     minimumCountColumns: 1,
  //     columns: [{
  //       field: 'state',
  //       title: __('State'),
  //       sortable: true,
  //       clickToSelect: true,
  //       class: 'col-sm-1',
  //       formatter: function(value, row, index) {
  //         switch(row.state) {
  //           case 'online':
  //             return [
  //               '<i class="fa fa-play" title="',
  //                 row.state,
  //               '"></i>'
  //             ].join('');
  //             break;

  //           default:
  //             return [
  //               '<i class="fa fa-exclamation-triangle" title="',
  //                 row.state,
  //               '"></i>'
  //             ].join('');
  //             break;
  //         }
  //       }
  //     }, {
  //       field: 'uname',
  //       title: __('Name'),
  //       sortable: true,
  //       clickToSelect: true
  //     }, {
  //       field: 'maintenance',
  //       title: __('Maintenance'),
  //       sortable: true,
  //       clickToSelect: true,
  //       class: 'col-sm-1',
  //       formatter: function(value, row, index) {
  //         if (row.maintenance) {
  //           return [
  //             '<i class="fa fa-toggle-on text-danger" title="',
  //               __('Yes'),
  //             '"></i>'
  //           ].join('');
  //         } else {
  //           return [
  //             '<i class="fa fa-toggle-off text-success" title="',
  //               __('No'),
  //             '"></i>'
  //           ].join('');
  //         }
  //       }
  //     }, {
  //       field: 'standby',
  //       title: __('Standby'),
  //       sortable: true,
  //       clickToSelect: true,
  //       class: 'col-sm-1',
  //       formatter: function(value, row, index) {
  //         if (row.standby) {
  //           return [
  //             '<i class="fa fa-toggle-on text-danger" title="',
  //               __('Yes'),
  //             '"></i>'
  //           ].join('');
  //         } else {
  //           return [
  //             '<i class="fa fa-toggle-off text-success" title="',
  //               __('No'),
  //             '"></i>'
  //           ].join('');
  //         }
  //       }
  //     }, {
  //       field: 'operate',
  //       title: __('Operations'),
  //       sortable: false,
  //       clickToSelect: false,
  //       class: 'col-sm-1',
  //       formatter: function(value, row, index) {
  //         var operations = []

  //         if (row.state != 'online') {
  //           operations.push([
  //             '<a href="javascript: void(0);" class="play" title="',
  //               __('Online'),
  //             '">',
  //               '<i class="fa fa-play"></i>',
  //             '</a> '
  //           ].join(''));
  //         }

  //         if (!row.standby) {
  //           operations.push([
  //             '<a href="javascript: void(0);" class="standby" title="',
  //               __('Standby'),
  //             '">',
  //               '<i class="fa fa-pause"></i>',
  //             '</a> '
  //           ].join(''));
  //         }

  //         if (!row.maintenance) {
  //           operations.push([
  //             '<a href="javascript: void(0);" class="maintenance" title="',
  //               __('Maintenance'),
  //             '">',
  //               '<i class="fa fa-wrench"></i>',
  //             '</a> '
  //           ].join(''));
  //         }

  //         operations.push([
  //           '<a href="javascript: void(0);" class="ready" title="',
  //             __('Ready'),
  //           '">',
  //             '<i class="fa fa-check"></i>',
  //           '</a> '
  //         ].join(''));

  //         operations.push([
  //           '<a href="javascript: void(0);" class="fence" title="',
  //             __('Fence'),
  //           '">',
  //             '<i class="fa fa-close"></i>',
  //           '</a> '
  //         ].join(''));

  //         operations.push([
  //           '<a href="javascript: void(0);" class="details" title="',
  //             __('Details'),
  //           '">',
  //             '<i class="fa fa-search"></i>',
  //           '</a> '
  //         ].join(''));

  //         operations.push([
  //           '<a href="javascript: void(0);" class="events" title="',
  //             __('Events'),
  //           '">',
  //             '<i class="fa fa-files-o"></i>',
  //           '</a>'
  //         ].join(''));

  //         // if (row.state != 'online') {
  //         //   operations.push([
  //         //     '<li>',
  //         //       '<a href="javascript: void(0);" class="play">',
  //         //         '<i class="fa fa-play"></i> ',
  //         //         __('Online'),
  //         //       '</a>',
  //         //     '</li>'
  //         //   ].join(''));
  //         // }

  //         // if (!row.standby) {
  //         //   operations.push([
  //         //     '<li>',
  //         //       '<a href="javascript: void(0);" class="standby">',
  //         //         '<i class="fa fa-pause"></i> ',
  //         //         __('Standby'),
  //         //       '</a>',
  //         //     '</li>'
  //         //   ].join(''));
  //         // }

  //         // if (!row.maintenance) {
  //         //   operations.push([
  //         //     '<li>',
  //         //       '<a href="javascript: void(0);" class="maintenance">',
  //         //         '<i class="fa fa-wrench"></i> ',
  //         //         __('Maintenance'),
  //         //       '</a>',
  //         //     '</li>'
  //         //   ].join(''));
  //         // }

  //         // operations.push([
  //         //   '<li>',
  //         //     '<a href="javascript: void(0);" class="ready">',
  //         //       '<i class="fa fa-check"></i> ',
  //         //       __('Ready'),
  //         //     '</a>',
  //         //   '</li>'
  //         // ].join(''));

  //         // operations.push([
  //         //   '<li>',
  //         //     '<a href="javascript: void(0);" class="fence">',
  //         //       '<i class="fa fa-close"></i> ',
  //         //       __('Fence'),
  //         //     '</a>',
  //         //   '</li>'
  //         // ].join(''));

  //         // operations.push([
  //         //   '<li class="divider"></li>'
  //         // ].join(''));

  //         // operations.push([
  //         //   '<li>',
  //         //     '<a href="javascript: void(0);" class="details">',
  //         //       '<i class="fa fa-search"></i> ',
  //         //       __('Details'),
  //         //     '</a>',
  //         //   '</li>'
  //         // ].join(''));

  //         // operations.push([
  //         //   '<li>',
  //         //     '<a href="javascript: void(0);" class="events">',
  //         //       '<i class="fa fa-files-o"></i> ',
  //         //       __('Events'),
  //         //     '</a>',
  //         //   '</li>'
  //         // ].join(''));

  //         // return [
  //         //   '<div class="btn-group">',
  //         //     '<button class="btn btn-default btn-xs dropdown-toggle" type="button" data-toggle="dropdown" aria-expanded="false">',
  //         //       __('Operations'),
  //         //       ' <span class="caret"></span>',
  //         //     '</button>',
  //         //     '<ul class="dropdown-menu" role="menu">',
  //         //       operations.join(''),
  //         //     '</ul>',
  //         //   '</div>',
  //         // ].join('');

  //         return operations.join('');
  //       }
  //     }]
  //   });
});
