#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2010 Novell Inc., Tim Serong <tserong@novell.com>
#                        All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it would be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Further, this software is distributed without any warranty that it is
# free of the rightful claim of any third person regarding infringement
# or the like.  Any license provided herein, whether implied or
# otherwise, applies only to this software file.  Patent licenses, if
# any, provided herein do not apply to combinations of this program with
# other software, or any other product whatsoever.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston MA 02111-1307, USA.
#
#======================================================================

HG = $(shell which hg 2>/dev/null)
# This gives current hg changeset hash (12 digits).  This is the reliable
# indicator of which version you've got.
BUILD_VERSION = $(shell \
	[ -f .hg_archival.txt ] && awk '/node:/ { print $$2 }' .hg_archival.txt | cut -c -12 || \
	([ -x "$(HG)" -a -d .hg ] && $(HG) id -i | cut -c -12 || echo 'unknown') )
# This gets the version from the most recent tag in the form "hawk-x.y.z"
# as a best-effort human-readable version number (e.g. 0.1.1 or 0.1.2-rc1).
# But to really know what you're running, you need the changeset hash above.
BUILD_TAG = $(shell awk --posix -Fhawk- '/[a-f0-9]{40} hawk-[0-9.]+/ { print $$2 }' .hgtags | tail -n 1)
ifeq "$(BUILD_TAG)" ""
BUILD_TAG = 0.0.0
endif

RPM_ROOT = $(shell pwd)
RPM_OPTS = --define "_sourcedir $(RPM_ROOT)"	\
	   --define "_specdir	$(RPM_ROOT)"	\
	   --define "_srcrpmdir	$(RPM_ROOT)"

# Override this when invoking make to install elsewhere, e.g.:
#   make WWW_BASE=/var/www install
WWW_BASE = /srv/www

# Override this to get a different init script (e.g. "redhat")
INIT_STYLE = suse

all: scripts/hawk.$(INIT_STYLE) hawk/config/lighttpd.conf tools/hawk_chkpwd
	(cd hawk; rake makemo; rake freeze:rails; rake freeze:gems)

%: %.in
	sed -e 's|@WWW_BASE@|$(WWW_BASE)|' $< > $@

tools/hawk_chkpwd: tools/hawk_chkpwd.c
	gcc -o $@ $< -lpam


clean:
	rm -rf hawk/locale
	rm -rf hawk/vendor
	rm -rf hawk/tmp
	rm -rf hawk/log
	rm -f hawk/config/lighttpd.conf
	rm -f scripts/hawk.{suse,redhat}

install:
	mkdir -p $(DESTDIR)$(WWW_BASE)/hawk/log
	mkdir -p $(DESTDIR)$(WWW_BASE)/hawk/tmp
	mkdir -p $(DESTDIR)$(WWW_BASE)/hawk/locale
	mkdir -p $(DESTDIR)$(WWW_BASE)/hawk/tmp
	mkdir -p $(DESTDIR)$(WWW_BASE)/hawk/tmp/cache
	mkdir -p $(DESTDIR)$(WWW_BASE)/hawk/tmp/pids
	mkdir -p $(DESTDIR)$(WWW_BASE)/hawk/tmp/sessions
	mkdir -p $(DESTDIR)$(WWW_BASE)/hawk/tmp/sockets
	# Get rid of cruft from packed gems
	-find hawk/vendor -name '*bak' -o -name '*~' -o -name '#*#' | xargs rm
	cp -a hawk/* $(DESTDIR)$(WWW_BASE)/hawk
	rm $(DESTDIR)$(WWW_BASE)/hawk/config/lighttpd.conf.in
	-chown -R hacluster.haclient $(DESTDIR)$(WWW_BASE)/hawk
	install -D -m 0755 scripts/hawk.$(INIT_STYLE) $(DESTDIR)/etc/init.d/hawk
	install -D -m 4750 tools/hawk_chkpwd $(DESTDIR)/usr/sbin/hawk_chkpwd
	-chown root.haclient $(DESTDIR)/usr/sbin/hawk_chkpwd

# Make a tar.bz2 named for the most recent human-readable tag
archive:
	rm -f hawk-$(BUILD_TAG).tar.bz2
	$(HG) archive -t tbz2 hawk-$(BUILD_TAG).tar.bz2
pot:
	(cd hawk; rake BUILD_TAG=$(BUILD_TAG) updatepo)

srpm: archive hawk.spec
	rm -f *.src.rpm
	rpmbuild -bs $(RPM_OPTS) hawk.spec

rpm: srpm
	rpmbuild --rebuild $(RPM_ROOT)/*.src.rpm

