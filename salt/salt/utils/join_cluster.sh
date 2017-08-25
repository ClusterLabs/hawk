#!/bin/sh
systemctl -q is-active pacemaker && exit
[ "$(hostname)" = "webui" ] && exit
while true; do
	ping -q -c 1 10.13.37.10 >/dev/null && break
	echo "[webui] First cluster node not yet online..."
	sleep 5
done
while true; do
	ssh -o StrictHostKeyChecking=no root@10.13.37.10 /usr/sbin/crm_mon -1 >/dev/null && break
	echo "[webui] Cluster not yet initialized..."
	sleep 5
done
/usr/sbin/crm cluster join -c 10.13.37.10 -i eth1 -y
