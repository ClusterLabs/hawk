#!/bin/sh

# install the pre-requisite packages.
zypper --non-interactive install automake autoconf php7 apache2-mod_php7 gd gd-devel lynx w3m perl-Net-SNMP

# Downloading The nagios-plugins Source
wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz
tar zxf nagios-plugins.tar.gz

cd nagios-plugins-release-2.2.1/
sudo ./tools/setup
sudo ./configure
sudo make
sudo make install

# Install nagios-nrpe
zypper in -y nrpe

# Install Nagios nrpe plugins
zypper in -y 'monitoring-plugins-*'

# Add the webui node (Nagios server), to the list of the allowed hosts
sed -i '/^allowed_hosts=/ s/$/,{{ pillar['ip_node_0'] }}/' /etc/nrpe.cfg

# restart the nrpe service
systemctl restart nrpe

