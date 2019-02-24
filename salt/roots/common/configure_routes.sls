# Check if running in SUSE's infrastructure
{% if pillar['vm_configure_routes'] == true -%}
# Install the script in /bin so it's available even after reboot (when the nfs directory is not mounted)
/home/vagrant/bin/configure_routes.sh:
  file.managed:
    - source: salt://utils/configure_routes.sh
    - user: root
    - group: root
    - mode: 755
    - template: jinja

# Install the systemd .service file
/etc/systemd/system/configure-routes.service:
  file.managed:
    - source: salt://files/configure-routes.service
    - user: root
    - group: root
    - mode: 644

# Start and enable the service
configure-routes:
  service.running:
    - enable: True
{%- endif %}
