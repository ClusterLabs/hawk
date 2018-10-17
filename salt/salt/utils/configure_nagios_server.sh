#!/bin/sh

# Install the pre-requisite packages.
zypper --non-interactive install automake autoconf php7 apache2-mod_php7 gd gd-devel lynx w3m libopenssl-devel perl-Net-SNMP

# Downloading the Nagios source
wget -O nagioscore.tar.gz https://github.com/NagiosEnterprises/nagioscore/archive/nagios-4.4.2.tar.gz
tar xzf nagioscore.tar.gz

# Compile
cd nagioscore-nagios-4.4.2/
./configure --with-httpd-conf=/etc/apache2/vhosts.d
make all

# Create the nagios user and group. The apache user is also added to the nagios group.
make install-groups-users
/usr/sbin/usermod -a -G nagios wwwrun

# Install the binary files, CGIs, and HTML files.
make install

# Install the service or daemon files and also configures them to start on boot.
make install-daemoninit

# Install and configures the external command file.
make install-commandmode

# Install the *SAMPLE* configuration files. These are required as Nagios needs some configuration files to allow it to start.
make install-config

# Install the Apache web server configuration files. Also configure Apache settings if required.
make install-webconf
/usr/sbin/a2enmod rewrite
/usr/sbin/a2enmod cgi
/usr/sbin/a2enmod version
/usr/sbin/a2enmod php7

# Fix Apache error: “Could not reliably determine the server's fully qualified domain name”
echo "ServerName localhost" | tee /etc/apache2/conf.d/fqdn.conf

# Create an Apache user account to be able to log into Nagios. (you will be prompted to provide a password for the account.)
htpasswd2 -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin nagios

# Downloading the nagios plugins Source
wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz
tar zxf nagios-plugins.tar.gz

# Installing the plugins
cd nagios-plugins-release-2.2.1/
./tools/setup
./configure
make
make install

# Change the owner of the /usr/local/nagios directory
chown -R nagios:nagios /usr/local/nagios

# Install the nrpe plugins on the server
zypper in -y monitoring-plugins-nrpe
cp /usr/lib/nagios/plugins/check_nrpe /usr/local/nagios/libexec
cp /usr/lib/nagios/plugins/nrpe_check_control /usr/local/nagios/libexec

# Change the HTTP port to 8000 in localhost.cfg
sed -i 's/check_http.*/check_http_port!8000/g' /usr/local/nagios/etc/objects/localhost.cfg
cat << 'EOT' >> /usr/local/nagios/etc/objects/localhost.cfg
define command {
    command_name check_http_port
    command_line $USER1$/check_http -I $HOSTADDRESS$ -p $ARG1$
}
EOT

# Add the cluster_api.cfg to nagios config file
sed -i '/cfg_file=\/usr\/local\/nagios\/etc\/objects\/templates.cfg/a cfg_file=\/usr\/local\/nagios\/etc\/objects\/cluster_api.cfg' /usr/local/nagios/etc/nagios.cfg

systemctl restart nagios
apachectl restart
