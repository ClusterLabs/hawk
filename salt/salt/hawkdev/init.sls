webui_packages:
  pkg.installed:
    - names:
      - pam-devel
      - libglue-devel

    - require:
      - pkg: common_packages

salt://utils/install_tools.sh:
  cmd.script:
    - require:
      - pkg: webui_packages

salt://utils/init_cluster.sh:
  cmd.script:
    - require:
      - cmd: "salt://utils/install_tools.sh"
    - env:
{% if 'vdb' in grains['disks'] %}
      - PDEV: /dev/vdb
      - PDEV2: /dev/vdb2
{% else %}
      - PDEV: /dev/sdb
      - PDEV2: /dev/sdb2
{% endif %}

salt://utils/configure_drbd.sh:
  cmd.script:
    - require:
      - file: /etc/drbd.d/global_common.conf
      - file: /etc/drbd.d/r0.res
      - cmd: "salt://utils/init_cluster.sh"

/root/initial.crm:
  file.managed:
    - source: salt://files/crm-initial.conf

apply_initial_configuration:
  cmd.run:
    - name: crm configure load update /root/initial.crm
    - require:
      - file: /root/initial.crm
      - cmd: "salt://utils/configure_drbd.sh"

# salt://utils/configure_bundle_crm.sh:
#   cmd.script:
#     - runas: root

/etc/systemd/system/hawk-development.service:
  file.managed:
    - source: salt://files/hawk-development.service
    - user: root
    - group: root
    - mode: 644

/etc/systemd/system/hawk-dev-backend.service:
  file.managed:
    - source: salt://files/hawk-dev-backend.service
    - user: root
    - group: root
    - mode: 644

/usr/bin/hawk:
  file.managed:
    - source: /vagrant/hawk/bin/hawk
    - user: root
    - group: root
    - mode: 755

