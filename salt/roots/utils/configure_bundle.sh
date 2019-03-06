#!/bin/sh

mkdir /etc/pacemaker
echo "authkey" > /etc/pacemaker/authkey

zypper ref
zypper --non-interactive in docker
systemctl enable --now docker

docker pull abelarbi/bundle_test:apache

mkdir -p /var/log/pacemaker/bundles/httpd-bundle-{0,1,2} \
  /var/local/containers/httpd-bundle-{0,1,2}

for i in 0 1 2; do cat >/var/local/containers/httpd-bundle-$i/index.html <<EOF
<html>
<head><title>Bundle test</title></head>
<body>
<h1>httpd-bundle-$i @ $(hostname)</h1>
</body>
</html>
EOF
done
