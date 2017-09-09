chrony_package:
  pkg.installed:
    - names:
        - chrony

chronyd:
  service.running:
    - enable: True
    - require:
        - pkg: chrony_package

