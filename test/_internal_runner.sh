#!/bin/sh

echo "**** Creating user / group ****"
oname=$1
ouid=$2
ogid=$3
cat /etc/group | awk '{ FS = ":" } { print $3 }' | grep -q $ogid || groupadd -g $ogid
id -u $oname >/dev/null 2>&1 || useradd -u $ouid -g $ogid $oname

echo "**** Install ruby dependencies ****"
cd /hawk/hawk
bundle.ruby2.4 config --global silence_root_warning 1
bundle.ruby2.4 install


echo "**** Run tests ****"
su $oname -c "ruby.ruby2.4 -- ./bin/rake test"
