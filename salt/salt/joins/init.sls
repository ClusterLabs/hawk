salt://utils/join_cluster.sh:
  cmd.script:
    - runas: root
    - template: jinja

salt://utils/nagios_nrpe.sh:
  cmd.script:
    - runas: root
    - template: jinja

