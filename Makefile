# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

VERSION = 2.0.1

RPM_ROOT = $(shell pwd)/rpm
RPM_OPTS = --define "_sourcedir $(RPM_ROOT)"	\
	   --define "_specdir	$(RPM_ROOT)"	\
	   --define "_srcrpmdir	$(RPM_ROOT)"

# Override this when invoking make to install elsewhere, e.g.:
#   make WWW_BASE=/usr/share WWW_TMP=/var/lib/hawk/tmp WWW_LOG=/var/log/hawk install
# log files are written to (WWW_LOG)
# temp files are written to (WWW_TMP)
# if these are not the defaults, symlinks are created
WWW_BASE = /usr/share
WWW_TMP = $(WWW_BASE)/hawk/tmp
WWW_LOG = $(WWW_BASE)/hawk/log

# Override this to append a suffix to the puma executable
# in the systemd service file
RUBY_SUFFIX =

# Override this to get a different init script (e.g. "redhat")
INIT_STYLE = suse

# Never set this to 1, it's used only within vagrant for development
WITHIN_VAGRANT = 0

# Base paths for Pacemaker binaries (note: overriding these will change
# paths used by hawk_invoke, but will have no effect on hard-coded paths
# in the rails app)
LIBDIR = /usr/lib
BINDIR = /usr/bin
SBINDIR = /usr/sbin

.PHONY: all clean tools

all: scripts/hawk.$(INIT_STYLE) scripts/hawk.service scripts/hawk-backend.service scripts/server.json tools
	(cd hawk; \
	 RAILS_ENV=production TEXTDOMAIN=hawk bin/rake gettext:pack; \
	 RAILS_ENV=production bin/rake assets:precompile)

%:: %.in
	sed \
		-e 's|@WWW_BASE@|$(WWW_BASE)|g' \
		-e 's|@LIBDIR@|$(LIBDIR)|g' \
		-e 's|@BINDIR@|$(BINDIR)|g' \
		-e 's|@SBINDIR@|$(SBINDIR)|g' \
		-e 's|@RUBY_SUFFIX@|$(RUBY_SUFFIX)|g' \
		-e 's|@WITHIN_VAGRANT@|$(WITHIN_VAGRANT)|g' \
		$< > $@

tools/hawk_chkpwd: tools/hawk_chkpwd.c tools/common.h
	gcc -fpie -pie $(CFLAGS) -o $@ $< -lpam


tools: tools/hawk_chkpwd

base/install:
	./scripts/create-directory-layout.sh "$(DESTDIR)" "$(WWW_BASE)" "$(WWW_LOG)" "$(WWW_TMP)"
	-find hawk/vendor -name '*bak' -o -name '*~' -o -name '#*#' -delete
	cp -a hawk/tmp/cache/* $(DESTDIR)$(WWW_BASE)/hawk/tmp/cache
	rm -rf hawk/tmp hawk/log
	cp -a hawk/* $(DESTDIR)$(WWW_BASE)/hawk
	-cp -a hawk/.bundle $(DESTDIR)$(WWW_BASE)/hawk
	install -D -m 0644 scripts/hawk.service $(DESTDIR)/usr/lib/systemd/system/hawk.service
	install -D -m 0644 scripts/hawk-backend.service $(DESTDIR)/usr/lib/systemd/system/hawk-backend.service
	install -D -m 0644 scripts/server.json $(DESTDIR)/etc/hawk/server.json


tools/install:
	install -D -m 4750 tools/hawk_chkpwd $(DESTDIR)/usr/sbin/hawk_chkpwd
	-chown root.haclient $(DESTDIR)/usr/sbin/hawk_chkpwd || true
	-chmod u+s $(DESTDIR)/usr/sbin/hawk_chkpwd

# TODO(should): Verify this is really clean (it won't get rid of .mo files,
# for example
clean:
	rm -rf hawk/tmp/*
	rm -rf hawk/log/*
	rm -f scripts/hawk.{suse,redhat,service}
	rm -f tools/hawk_chkpwd
	rm -f tools/common.h

# Note: chown & chmod here are only necessary if *not* doing an RPM build
# (the spec sets file ownership/perms for RPMs).
# TODO(should): Make an option to install either the init script or the
# systemd service file (presently this installs the systemd service file)
install: base/install tools/install

# Make a tar.bz2 named for the version
archive:
	rm -f hawk-$(VERSION).tar.bz2
	git archive --prefix=hawk-$(VERSION)/ HEAD | bzip2 > rpm/hawk-$(VERSION).tar.bz2

# The touch here is necessary to ensure the POT file is always updated
# completely, even if it somehow winds up with a newer mtime than other
# source files
pot:
	@echo "** WARNING: THIS SCREWS UP Project-Id-Version IN THE .POT FILE"
	@echo "**          DO NOT COMMIT WITHOUT FIXING THIS!"
	touch -d '2010-01-16T22:20:54+1100' hawk/locale/hawk.pot
	(cd hawk; rake gettext:find)

srpm: archive
	rm -f $(RPM_ROOT)/*.src.rpm
	cd rpm && rpmbuild -bs $(RPM_OPTS) hawk.spec

rpm: srpm
	rpmbuild --rebuild $(RPM_ROOT)/*.src.rpm
