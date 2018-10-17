salt://utils/join_cluster.sh:
  cmd.script:
    - runas: root
    - template: jinja

salt://utils/configure_nagios_client.sh:
  cmd.script:
    - runas: root
    - template: jinja

