#!/bin/sh
systemctl -q is-active pacemaker && exit
[ "$(hostname)" != "webui" ] && exit
PDEV=/dev/vdb
[ -e $PDEV ] || PDEV=/dev/sdb
/usr/sbin/crm cluster init --name "hawkdev" -y -i eth1 -t ocfs2 -p $PDEV
