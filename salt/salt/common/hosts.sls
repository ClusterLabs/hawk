webui:
  host.present:
    - ip: {{ pillar['ip_node_0'] }}

node1:
  host.present:
    - ip: {{ pillar['ip_node_1'] }}

node2:
  host.present:
    - ip: {{ pillar['ip_node_2'] }}
