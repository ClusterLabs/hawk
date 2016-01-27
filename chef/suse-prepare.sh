#!/bin/sh
mkdir -p /opt/chef/bin
[ -f /opt/chef/bin/knife ] || ln -s /usr/bin/knife /opt/chef/bin/knife
[ -f /opt/chef/bin/chef-solo ] || ln -s /usr/bin/chef-solo /opt/chef/bin/chef-solo
