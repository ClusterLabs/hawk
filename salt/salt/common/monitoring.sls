server:monitoring:
  pkgrepo.managed:
    - humanname: server:monitoring
    - baseurl: https://download.opensuse.org/repositories/server:/monitoring/openSUSE_Leap_15.0/
    - refresh: True
    - gpgautoimport: True

devel:tools:
  pkgrepo.managed:
    - humanname: devel:tools
    - baseurl: http://download.opensuse.org/repositories/devel:/tools/openSUSE_Leap_15.0/
    - refresh: True
    - gpgautoimport: True

monitoring_packages:
  pkg.installed:
    - version: 'latest'
    - refresh: True
    - names:
        - git
        - go1.10
        - golang-github-prometheus-prometheus
        - golang-github-prometheus-promu
        - golang-github-prometheus-node_exporter
        - phantomjs
        - grafana
    - require:
        - pkgrepo: server:monitoring
        - pkgrepo: devel:tools

/etc/profile.d/go.sh:
  file.managed:
    - source: salt://files/go.sh

'source /etc/profile.d/go.sh':
  cmd.run

gobin:
   environ.setenv:
     - name: GOBIN
     - value: /usr/bin
     - update_minion: True

'curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh':
  cmd.run

prometheus:
  service.running:
    - enable: True

prometheus-node_exporter:
  service.running:
    - enable: True

salt://utils/pacemaker_exporter.sh:
  cmd.script:
    - runas: root

/etc/systemd/system/pacemaker-exporter.service:
  file.managed:
    - source: salt://files/pacemaker-exporter.service
    - user: root
    - group: root
    - mode: 644

pacemaker-exporter:
  service.running:
    - require:
      - file: /etc/systemd/system/pacemaker-exporter.service
    - watch:
      - /etc/systemd/system/pacemaker-exporter.service
    - enable: True
