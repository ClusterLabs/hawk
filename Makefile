all:
	(cd hawk; rake makemo; rake rails:freeze:gems; rake gems:unpack)

install:
	mkdir -p /srv/www/hawk/log
	mkdir -p /srv/www/hawk/tmp
	mkdir -p /srv/www/hawk/locale
	mkdir -p /srv/www/hawk/tmp
	mkdir -p /srv/www/hawk/tmp/cache
	mkdir -p /srv/www/hawk/tmp/pids
	mkdir -p /srv/www/hawk/tmp/sessions
	mkdir -p /srv/www/hawk/tmp/sockets
	cp -a hawk/* /srv/www/hawk
	-chown -R hacluster.haclient /srv/www/hawk
	install -D -m 0755 scripts/hawk /etc/init.d/hawk
	ln -s -f /etc/init.d/hawk /sbin/rchawk

pot:
	(cd hawk; rake updatepo)

