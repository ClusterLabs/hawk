resource r0 {
	device /dev/drbd0;
	disk {{ disk }};
	meta-disk internal;
	on webui {
		address {{ pillar['ip_node_0'] }}:7788;
		node-id 0;
	}
	on node1 {
		address {{ pillar['ip_node_1'] }}:7788;
		node-id 1;
	}
	on node2 {
		address {{ pillar['ip_node_2'] }}:7788;
		node-id 2;
	}
	disk {
		resync-rate 1M;
	}
	connection-mesh {
		hosts webui node1 node2;
	}
}
