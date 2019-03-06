{% import_yaml "/vagrant/vconf.yml" as vagrant %}

ip_node_0: {{ vagrant.ip_node_0 }}
ip_node_1: {{ vagrant.ip_node_1 }}
ip_node_2: {{ vagrant.ip_node_2 }}
ip_vip: {{ vagrant.ip_vip }}
vm_configure_routes: {{ vagrant.vm_configure_routes }}
vm_routes_config: {{ vagrant.vm_routes_config }}
