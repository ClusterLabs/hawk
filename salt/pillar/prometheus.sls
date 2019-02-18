prometheus:
  server:
    version: 2.7
    enabled: true
    is_container: false
    dir:
      config: /etc/prometheus
      data: /var/lib/prometheus/metrics
    pkgs_repo:
      server:monitoring:
        - humanname: server:monitoring
        - baseurl: https://download.opensuse.org/repositories/server:/monitoring/openSUSE_Leap_15.0/
        - refresh: True
        - gpgautoimport: True
    pkgs:
      prometheus:
        - name: golang-github-prometheus-prometheus
        - version: 2.7.1
        - fromrepo: server:monitoring
      promu:
        - name: golang-github-prometheus-promu
        - version: 0.2.0
        - fromrepo: server:monitoring
    bind:
      port: 9090
      address: 0.0.0.0
    external_port: 15010
    target:
      dns:
        enabled: true
        endpoint:
          - name: 'pushgateway'
            domain:
            - 'tasks.prometheus_pushgateway'
            type: A
            port: 9091
          - name: 'prometheus'
            domain:
            - 'tasks.prometheus_server'
            type: A
            port: 9090
      kubernetes:
        enabled: true
        api_ip: 127.0.0.1
        ssl_dir: /opt/prometheus/config
        cert_name: prometheus-server.crt
        key_name: prometheus-server.key
      etcd:
        endpoint:
          scheme: https
          ssl_dir: /opt/prometheus/config
          cert_name: prometheus-server.crt
          key_name: prometheus-server.key
          member:
            - host: ${_param:cluster_node01_address}
              port: ${_param:cluster_node01_port}
            - host: ${_param:cluster_node02_address}
              port: ${_param:cluster_node02_port}
            - host: ${_param:cluster_node03_address}
              port: ${_param:cluster_node03_port}
    recording:
      instance:fd_utilization:
        query: >-
          process_open_fds / process_max_fds
    storage:
      local:
        retention: "360h"
    alertmanager:
      notification_queue_capacity: 10000
    config:
      global:
        scrape_interval: "15s"
        scrape_timeout: "15s"
        evaluation_interval: "1m"
        external_labels:
          region: 'region1'
