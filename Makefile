all:
	(cd hawk; rake makemo; rake rails:freeze:gems; rake gems:unpack)

install:
	mkdir -p $(DESTDIR)/srv/www/hawk/log
	mkdir -p $(DESTDIR)/srv/www/hawk/tmp
	mkdir -p $(DESTDIR)/srv/www/hawk/locale
	mkdir -p $(DESTDIR)/srv/www/hawk/tmp
	mkdir -p $(DESTDIR)/srv/www/hawk/tmp/cache
	mkdir -p $(DESTDIR)/srv/www/hawk/tmp/pids
	mkdir -p $(DESTDIR)/srv/www/hawk/tmp/sessions
	mkdir -p $(DESTDIR)/srv/www/hawk/tmp/sockets
	cp -a hawk/* $(DESTDIR)/srv/www/hawk
	-chown -R hacluster.haclient $(DESTDIR)/srv/www/hawk
	install -D -m 0755 scripts/hawk $(DESTDIR)/etc/init.d/hawk

pot:
	(cd hawk; rake updatepo)

