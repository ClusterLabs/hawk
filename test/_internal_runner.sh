#!/bin/sh

echo "**** Creating user / group ****"
oname=$1
ouid=$2
ogid=$3
awk '{ FS = ":" } { print $3 }' < /etc/group | grep -q $ogid || groupadd -g $ogid
id -u $oname >/dev/null 2>&1 || useradd -u $ouid -g $ogid $oname
mkdir -p /home/$oname
chown -R $oname /home/$oname

export BUNDLE_JOBS=2
export BUNDLE_PATH=/bundle
export RAILS_ENV=test

echo "**** Install ruby dependencies ****"
cd /hawk/hawk || exit
bundle.ruby2.5 config --global silence_root_warning 1
bundle.ruby2.5 install


echo "**** Run tests ****"
su $oname -c "ruby.ruby2.5 -- ./bin/bundle exec rspec"
