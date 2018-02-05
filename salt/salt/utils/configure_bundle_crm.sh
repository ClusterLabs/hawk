#!/bin/sh
crm configure primitive httpd-apache ocf:heartbeat:apache
crm configure bundle httpd \
  docker image=abelarbi/bundle_test:apache replicas=3 \
  network ip-range-start=10.13.37.10 host-netmask=24 \
  port-mapping port=80 \
  storage \
    storage-mapping id=httpd-root target-dir=/var/www/html source-dir=/srv/www options=rw \
    storage-mapping id=httpd-logs target-dir=/var/log/apache2 source-dir=/var/log/pacemaker/bundles options=rw \
  primitive httpd-apache
