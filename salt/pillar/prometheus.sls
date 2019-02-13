prometheus:
  server:
    version: 2.0
    enabled: true
    dir:
        config: /etc/prometheus
        data: /var/lib/prometheus/metrics
    bind:
        port: 9090
        address: 0.0.0.0


