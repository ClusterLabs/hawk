#!/bin/sh

# install the pre-requisite packages.
zypper --non-interactive install automake autoconf php7 apache2-mod_php7 gd gd-devel lynx w3m libopenssl-devel

# Downloading the Source
wget -O nagioscore.tar.gz https://github.com/NagiosEnterprises/nagioscore/archive/nagios-4.4.2.tar.gz
tar xzf nagioscore.tar.gz

# Compile
cd nagioscore-nagios-4.4.2/
./configure --with-httpd-conf=/etc/apache2/vhosts.d
make all

# Create the nagios user and group. The apache user is also added to the nagios group.
make install-groups-users
/usr/sbin/usermod -a -G nagios wwwrun

# install the binary files, CGIs, and HTML files.
make install

# install the service or daemon files and also configures them to start on boot.
make install-daemoninit

# install and configures the external command file.
make install-commandmode

# install the *SAMPLE* configuration files. These are required as Nagios needs some configuration files to allow it to start.
make install-config

# install the Apache web server configuration files. Also configure Apache settings if required.
make install-webconf
/usr/sbin/a2enmod rewrite
/usr/sbin/a2enmod cgi
/usr/sbin/a2enmod version
/usr/sbin/a2enmod php7

echo "ServerName localhost" | sudo tee /etc/apache2/conf.d/fqdn

systemctl enable apache2.service

# create an Apache user account to be able to log into Nagios. (you will be prompted to provide a password for the account.)
htpasswd2 -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin nagios
systemctl start apache2.service
systemctl start nagios.service


## Plugins

# Installing plugins prerequisites
zypper in -y perl-Net-SNMP

# Downloading The Source
wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz
tar zxf nagios-plugins.tar.gz


cd nagios-plugins-release-2.2.1/
sudo ./tools/setup
sudo ./configure
sudo make
sudo make install


# Change the owner of the /usr/local/nagios directory
chown -R nagios:nagios /usr/local/nagios



# Install the nrpe plugins on the server
zypper in -y monitoring-plugins-nrpe
sudo cp /usr/lib/nagios/plugins/check_nrpe /usr/local/nagios/libexec
sudo cp /usr/lib/nagios/plugins/nrpe_check_control /usr/local/nagios/libexec


# Edit the localhost.cfg as well to replace the apache2 port
# Add 8000 to the  /usr/local/nagios/etc/objects/localhost.cfg, and change check_http to check_http_port:
# Define a service to check HTTP on the local machine.
# Disable notifications for this service by default, as not all users may have HTTP enabled.

sed -i 's/check_http.*/check_http_port!8000/g' /usr/local/nagios/etc/objects/localhost.cfg

cat << 'EOT' >> /usr/local/nagios/etc/objects/localhost.cfg
define command {
    command_name check_http_port
    command_line $USER1$/check_http -I $HOSTADDRESS$ -p $ARG1$
}
EOT



# add this to /usr/local/nagios/etc/nagios.cfg (see the other jinja file)
sed -i '/cfg_file=\/usr\/local\/nagios\/etc\/objects\/templates.cfg/a cfg_file=\/usr\/local\/nagios\/etc\/objects\/cluster_api.cfg' /usr/local/nagios/etc/nagios.cfg







