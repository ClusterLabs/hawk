#!/bin/sh

rm -f /vagrant/hawk/Gemfile.lock
zypper ref
zypper up  -y --replacefiles sbd ruby2.5-rubygem-sass-listen resource-agents   pacemaker ocfs2-tools libqb	 libdlm	 hawk2	 hawk-apiserver	 ha-cluster-bootstrap  fence-agents  drbd-utils	 drbd	 csync2	 crmsh	 corosync
zypper in -y ruby-devel
zypper up -y ruby2.5-rubygem-*
zypper in -y ruby2.5-rubygem-web-console ruby2.5-rubygem-byebug ruby2.5-rubygem-spring ruby2.5-rubygem-uglifier

