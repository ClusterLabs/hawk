#!/bin/sh
crm configure primitive httpd-apache ocf:heartbeat:apache
crm configure bundle httpd \
  docker image=abelarbi/bundle_test:apache replicas=3 options="--security-opt apparmor:unconfined" \
  network ip-range-start={{ pillar['ip_bundle_1'] }}   host-netmask=24 \
  port-mapping port=80 \
  storage \
    storage-mapping id=httpd-root target-dir=/var/www/html source-dir=/srv/www options=rw \
    storage-mapping id=httpd-logs target-dir=/var/log/apache2 source-dir=/var/log/pacemaker/bundles options=rw \
  primitive httpd-apache


crm configure primitive dummy_res Dummy \
  op monitor interval=30
crm configure bundle dummy \
  docker image=abelarbi/bundle_test:apache replicas=3 options="--security-opt apparmor:unconfined" \
  network ip-range-start={{ pillar['ip_bundle_2'] }}  host-netmask=24 \
  primitive dummy_res
