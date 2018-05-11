#!/bin/sh
crm configure show ms-DRBD 1>/dev/null 2>&1 && exit
drbdadm dump all
drbdadm create-md r0
drbdadm up r0
drbdadm new-current-uuid --clear-bitmap r0/0
drbdadm primary --force r0
mkfs.ext4 /dev/drbd0
crm script run drbd id=DRBD drbd_resource=r0
