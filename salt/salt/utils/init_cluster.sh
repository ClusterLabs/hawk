#!/bin/sh
systemctl -q is-active pacemaker && exit
[ "$(hostname)" != "webui" ] && exit

# Check if OCFS2 disk is already
# formatted for a different cluster name...
if [ -e "$PDEV2" ] && tunefs.ocfs2 -Q "%N" "$PDEV2" 1>/dev/null 2>&1; then
	mkfs.ocfs2 --force --cluster-stack pcmk --cluster-name hawkdev -N 4 -x "$PDEV2"
fi

/usr/sbin/crm cluster init --name "hawkdev" -y -i eth1 -t ocfs2 -p $PDEV

# Configure OCFS2 max node count
if [ "$(tunefs.ocfs2 -Q "%N" "$PDEV2")" != "4" ]; then
    crm -w resource stop c-clusterfs
    tunefs.ocfs2 -N 4 "$PDEV2"
    crm -w resource start c-clusterfs
fi
