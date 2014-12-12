#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2013 SUSE LLC, All Rights Reserved.
#
# Author: Tim Serong <tserong@suse.com>
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

GIT = $(shell which git 2>/dev/null)
# This gives current changeset hash (7 digits).  This is the reliable
# indicator of which version you've got.
BUILD_VERSION = $(shell git log --pretty="format:%h" -n 1)
# This gets the version from the most recent tag in the form "hawk-x.y.z"
# as a best-effort human-readable version number (e.g. 0.1.1 or 0.1.2-rc1).
# But to really know what you're running, you need the changeset hash above.
BUILD_TAG = $(shell git describe --tags --abbrev=0 | sed -e 's/^hawk-//')
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

# Set this to true to bundle gems inside rpm
BUNDLE_GEMS = false

# Set this never to 1, it's used only within vagrant for development
WITHIN_VAGRANT = 0

# Base paths for Pacemaker binaries (note: overriding these will change
# paths used by hawk_invoke, but will have no effect on hard-coded paths
# in the rails app)
LIBDIR = /usr/lib
BINDIR = /usr/bin
SBINDIR = /usr/sbin

all: scripts/hawk.$(INIT_STYLE) scripts/hawk.service hawk/config/lighttpd.conf tools/hawk_chkpwd tools/hawk_monitor tools/hawk_invoke
	(cd hawk; \
	 TEXTDOMAIN=hawk rake gettext:pack && \
	 if $(BUNDLE_GEMS) ; then \
		# Ignore gems from test \
		export BUNDLE_WITHOUT=test && \
		# Generate Gemfile.lock \
		bundle list && \
		# Strip unwanted gems from Gemfile.lock \
		sed -i -e '/\brdoc\b/d' Gemfile.lock && \
		# Finally package and install the gems \
		bundle package && bundle install --deployment ; \
	 fi)

%:: %.in
	sed \
		-e 's|@WWW_BASE@|$(WWW_BASE)|' \
		-e 's|@LIBDIR@|$(LIBDIR)|' \
		-e 's|@BINDIR@|$(BINDIR)|' \
		-e 's|@SBINDIR@|$(SBINDIR)|' \
		-e 's|@WITHIN_VAGRANT@|$(WITHIN_VAGRANT)|' \
		$< > $@

tools/hawk_chkpwd: tools/hawk_chkpwd.c tools/common.h
	gcc -fpie -pie $(CFLAGS) -o $@ $< -lpam

tools/hawk_monitor: tools/hawk_monitor.c
	gcc $(CFLAGS) \
		$(shell pkg-config --cflags glib-2.0) \
		$(shell pkg-config --cflags libxml-2.0) \
		-I/usr/include/pacemaker -I/usr/include/heartbeat \
		-o $@ $< \
		-lcib -lcrmcommon -lqb -Wall \
		$(shell pkg-config --libs glib-2.0) \
		$(shell pkg-config --libs libxml-2.0)

# TODO(must): This is inching towards becoming annoying: want better build infrastructure/deps
tools/hawk_invoke: tools/hawk_invoke.c tools/common.h
	gcc -fpie -pie $(CFLAGS) -o $@ $<

base/install:
	mkdir -p $(DESTDIR)$(WWW_BASE)/hawk/log
	mkdir -p $(DESTDIR)$(WWW_BASE)/hawk/tmp
	mkdir -p $(DESTDIR)$(WWW_BASE)/hawk/locale
	mkdir -p $(DESTDIR)$(WWW_BASE)/hawk/tmp
	mkdir -p $(DESTDIR)$(WWW_BASE)/hawk/tmp/cache
	mkdir -p $(DESTDIR)$(WWW_BASE)/hawk/tmp/explorer
	mkdir -p $(DESTDIR)$(WWW_BASE)/hawk/tmp/explorer/uploads
	mkdir -p $(DESTDIR)$(WWW_BASE)/hawk/tmp/pids
	mkdir -p $(DESTDIR)$(WWW_BASE)/hawk/tmp/sessions
	mkdir -p $(DESTDIR)$(WWW_BASE)/hawk/tmp/sockets
	mkdir -p $(DESTDIR)$(WWW_BASE)/hawk/tmp/home
	# Get rid of cruft from packed gems
	-find hawk/vendor -name '*bak' -o -name '*~' -o -name '#*#' | xargs rm
	cp -a hawk/* $(DESTDIR)$(WWW_BASE)/hawk
	-cp -a hawk/.bundle $(DESTDIR)$(WWW_BASE)/hawk
	rm $(DESTDIR)$(WWW_BASE)/hawk/config/lighttpd.conf.in
	-chown -R hacluster.haclient $(DESTDIR)$(WWW_BASE)/hawk/log
	-chown -R hacluster.haclient $(DESTDIR)$(WWW_BASE)/hawk/tmp
	-chmod g+w $(DESTDIR)$(WWW_BASE)/hawk/tmp/home
	-chmod g+w $(DESTDIR)$(WWW_BASE)/hawk/tmp/explorer
	install -D -m 0644 scripts/hawk.service $(DESTDIR)/usr/lib/systemd/system/hawk.service

tools/install:
	install -D -m 4750 tools/hawk_chkpwd $(DESTDIR)/usr/sbin/hawk_chkpwd
	-chown root.haclient $(DESTDIR)/usr/sbin/hawk_chkpwd
	-chmod u+s $(DESTDIR)/usr/sbin/hawk_chkpwd

	install -D -m 4750 tools/hawk_invoke $(DESTDIR)/usr/sbin/hawk_invoke
	-chown root.haclient $(DESTDIR)/usr/sbin/hawk_invoke
	-chmod u+s $(DESTDIR)/usr/sbin/hawk_invoke

	install -D -m 0755 tools/hawk_monitor $(DESTDIR)/usr/sbin/hawk_monitor
	ln -sf /usr/sbin/hawk_monitor $(DESTDIR)$(WWW_BASE)/hawk/public/monitor

# TODO(should): Verify this is really clean (it won't get rid of .mo files,
# for example
clean:
	rm -rf hawk/vendor
	rm -rf hawk/tmp
	rm -rf hawk/log
	rm -f hawk/config/lighttpd.conf
	rm -f scripts/hawk.{suse,redhat,service}
	rm -f tools/hawk_chkpwd
	rm -f tools/hawk_monitor
	rm -f tools/hawk_invoke
	rm -f tools/common.h

# Note: chown & chmod here are only necessary if *not* doing an RPM build
# (the spec sets file ownership/perms for RPMs).
# TODO(should): Make an option to install either the init script or the
# systemd service file (presently this installs the systemd service file)
install: base/install tools/install

# Make a tar.bz2 named for the most recent human-readable tag
archive:
	rm -f hawk-$(BUILD_TAG).tar.bz2
	$(GIT) archive --prefix=hawk-$(BUILD_TAG)/ HEAD | bzip2 > hawk-$(BUILD_TAG).tar.bz2

# The touch here is necessary to ensure the POT file is always updated
# completely, even if it somehow winds up with a newer mtime than other
# source files
pot:
	@echo "** WARNING: THIS SCREWS UP Project-Id-Version IN THE .POT FILE"
	@echo "**          DO NOT COMMIT WITHOUT FIXING THIS!"
	touch -d '2010-01-16T22:20:54+1100' hawk/locale/hawk.pot
	(cd hawk; rake gettext:find)

srpm: archive hawk.spec
	rm -f *.src.rpm
	rpmbuild -bs $(RPM_OPTS) hawk.spec

rpm: srpm
	rpmbuild --rebuild $(RPM_ROOT)/*.src.rpm

