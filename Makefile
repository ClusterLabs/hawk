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

all:
	(cd hawk; rake makemo; rake rails:freeze:gems; rake gems:unpack)

clean:
	rm -rf hawk/locale
	rm -rf hawk/vendor

install:
	mkdir -p $(DESTDIR)/srv/www/hawk/log
	mkdir -p $(DESTDIR)/srv/www/hawk/tmp
	mkdir -p $(DESTDIR)/srv/www/hawk/locale
	mkdir -p $(DESTDIR)/srv/www/hawk/tmp
	mkdir -p $(DESTDIR)/srv/www/hawk/tmp/cache
	mkdir -p $(DESTDIR)/srv/www/hawk/tmp/pids
	mkdir -p $(DESTDIR)/srv/www/hawk/tmp/sessions
	mkdir -p $(DESTDIR)/srv/www/hawk/tmp/sockets
	# Get rid of cruft from packed gems
	find hawk/vendor -name '*bak' -o -name '*~' -o -name '#*#' | xargs rm
	cp -a hawk/* $(DESTDIR)/srv/www/hawk
	-chown -R hacluster.haclient $(DESTDIR)/srv/www/hawk
	install -D -m 0755 scripts/hawk $(DESTDIR)/etc/init.d/hawk

# Make a tar.bz2 named for the most recent human-readable tag
archive:
	$(HG) archive -t tbz2 hawk-$(BUILD_TAG).tar.bz2
pot:
	(cd hawk; rake BUILD_TAG=$(BUILD_TAG) updatepo)

