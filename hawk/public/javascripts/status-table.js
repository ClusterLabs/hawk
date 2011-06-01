//======================================================================
//                        HA Web Konsole (Hawk)
// --------------------------------------------------------------------
//            A web-based GUI for managing and monitoring the
//          Pacemaker High-Availability cluster resource manager
//
// Copyright (c) 2009-2011 Novell Inc., Tim Serong <tserong@novell.com>
//                        All Rights Reserved.
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

/* Structure is:

   +-----------------------------------------+
   | +-[.node]-+ +-[.node]-+ +-[.inactive]-+ |
   | | [.rsrc] | | [.rsrc] | | [.rsrc      | |
   | | [.rsrc] | | [.rsrc] | | [.rsrc      | |
   | | [.rsrc] | | [.rsrc] | | [.rsrc      | |
   | +---------+ +---------+ +-------------+ |
   +-----------------------------------------+

Notion being nodes come and go by adding columns, resources come and
go by appending to each row.  So there's one HTML table with one row,
one column per node (plus one for the inactives).  Within each cell we
just add divs for resources.

*/
var table_view = {
  create: function() {
    $("#content").prepend($('<div id="table" style="display: none;"><table style="display: none;"><tr><td></td></tr></div>'));
  },
  destroy: function() {
    // NYI
  },
  update: function() {
    // Add/update nodes, then add/update resources
  },
  hide: function() {
    $("#table").hide();
  }
};

