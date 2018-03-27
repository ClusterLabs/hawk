#!/bin/sh
#
# Script which tries to bootstrap a Hawk development environment

BASE="$HOME/hawk"

echo "*** Add Virtualization repository"
if grep 'VERSION="Tumbleweed"' < /etc/os-release >/dev/null 2>&1; then
	sudo zypper ar http://download.opensuse.org/repositories/Virtualization/openSUSE_Factory/ Virtualization
elif grep 'VERSION="42.1"' < /etc/os-release >/dev/null 2>&1; then
	sudo zypper ar http://download.opensuse.org/repositories/Virtualization/openSUSE_Leap_42.1/ Virtualization
elif grep 'VERSION="42.2"' < /etc/os-release >/dev/null 2>&1; then
	sudo zypper ar http://download.opensuse.org/repositories/Virtualization/openSUSE_Leap_42.2/ Virtualization
elif grep 'VERSION="42.3"' < /etc/os-release >/dev/null 2>&1; then
	sudo zypper ar http://download.opensuse.org/repositories/Virtualization/openSUSE_Leap_42.3/ Virtualization
else
	osver="$(grep 'VERSION=' < /etc/os-release)"
	echo "Unknown OS version $osver"
	exit
fi
echo "*** zypper refresh"
sudo zypper refresh
echo "*** Install development tools"
sudo zypper install git devel_C_C++ ruby-devel vagrant virtualbox nfs-client nfs-kernel-server

cd "$(dirname "$BASE")" || exit

if [ ! -d "$BASE" ]; then
	echo "*** Clone hawk repository to $BASE..."
	git clone git@github.com:ClusterLabs/hawk "$BASE"
fi

cd "$BASE" || exit

echo "*** Install vagrant-bindfs plugin"
if vagrant plugin list | grep bindfs >/dev/null 2>&1; then
	echo "Already installed."
else
	vagrant plugin install vagrant-bindfs || exit
fi

echo "*** Starting development VM"
vagrant up webui
