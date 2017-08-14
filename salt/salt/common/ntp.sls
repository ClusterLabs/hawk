ntp_package:
  pkg.installed:
    - names:
        - ntp

ntpd:
  service.running:
    - enable: True
    - require:
        - pkg: ntp_package

