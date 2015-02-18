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

//= require_tree ./gettext/locale
//= require_self

$(function() {
  var locale = $('html').attr('lang');

  var i18n = new Jed(
    locales[locale] || {}
  );

  window.__ = function() {
    return i18n.gettext.apply(i18n, arguments)
  }

  window.n__ = function() {
    return i18n.ngettext.apply(i18n, arguments)
  }

  window.s__ = function(key) {
    return __(key).split('|').pop();
  }

  window.gettext = window.__;
  window.ngettext = window.n__;
  window.sgettext = window.s__;

  window.i18n = i18n;
});
