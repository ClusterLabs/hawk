# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version ">= 2.1.0"
require_relative './vagrant_config' if File.exists?('vagrant_config.rb')

# Virtual Machine Prefix: Please, include a meaninful name
VM_PREFIX_NAME = ENV["VM_PREFIX_NAME"] || 'hawk'

def host_bind_address
  ENV["VAGRANT_INSECURE_FORWARDS"] =~ /^(y(es)?|true|on)$/i ? '*' : '127.0.0.1'
end

$shared_disk = '_shared_disk'
$shared_disk_size = 128 # MB

$drbd_disk = '_drbd_disk'
$drbd_disk_size = 256 # MB

# Create and attach shared SBD/OCFS2 disk for VirtualBox
class VagrantPlugins::ProviderVirtualBox::Action::SetName
  alias_method :original_call, :call
  def call(env)
    disk_file = "#{$shared_disk}.vdi"
    ui = env[:ui]
    driver = env[:machine].provider.driver
    uuid = driver.instance_eval { @uuid }
    if !File.exist?(disk_file)
      ui.info "Creating storage file '#{disk_file}'..."
      driver.execute('createhd', "--filename", disk_file, "--size", "#{$shared_disk_size}", '--variant', 'fixed')
      driver.execute('modifyhd', disk_file, '--type', 'shareable')
    end
    ui.info "Attaching '#{disk_file}'..."
    driver.execute('storageattach', uuid, '--storagectl', "SATA Controller", '--port', "1", '--device', "0", '--type', 'hdd', '--medium', disk_file)

    name = env[:machine].provider_config.name
    disk_file = "#{$drbd_disk}_#{name}.vdi"
    if !File.exist?(disk_file)
      ui.info "Creating storage file '#{disk_file}'..."
      driver.execute('createhd', "--filename", disk_file, "--size", "#{$drbd_disk_size}", '--variant', 'fixed')
    end
    ui.info "Attaching '#{disk_file}'..."
    driver.execute('storageattach', uuid, '--storagectl', "SATA Controller", '--port', "2", '--device', "0", '--type', 'hdd', '--medium', disk_file)

    original_call(env)
  end
end

# Shared configuration for all VMs
def configure_machine(machine, idx, roles, memory, cpus)

  machine.vm.provider :libvirt do |provider, override|
    provider.default_prefix = VM_PREFIX_NAME
    provider.host = ENV["VM_HOST"] if ENV["VM_HOST"]
    provider.connect_via_ssh = true
    provider.username = ENV["VM_USERNAME"] if ENV["VM_USERNAME"]
    provider.password = ENV["VM_PASSWORD"] if ENV["VM_PASSWORD"]
    provider.driver = "kvm"
    provider.disk_bus = 'virtio'
    provider.memory = memory
    provider.cpus = cpus
    provider.nic_model_type = "rtl8139"
    provider.volume_cache = "default"
    provider.graphics_type = "spice"
    provider.watchdog model: "i6300esb", action: "reset"
    provider.graphics_port = 9200 + idx
    provider.storage :file, path: "#{$shared_disk}.raw", size: "#{$shared_disk_size}M", type: 'raw', cache: 'none', allow_existing: true, shareable: true
    provider.storage :file, path: "#{$drbd_disk}-#{machine.vm.hostname}.raw", size: "#{$drbd_disk_size}M", type: 'raw', allow_existing: true
    provider.cpu_mode = 'host-passthrough'
    provider.storage_pool_name = "default"
    provider.management_network_name = "vagrant-libvirt"
  end

  # Port forwarding
  machine.vm.network :forwarded_port, host_ip: host_bind_address, guest: 22, host: 3022 + (idx * 100)
  machine.vm.network :forwarded_port, host_ip: host_bind_address, guest: 7630, host: 7630 + idx
  if defined?(GC)
    machine.vm.network :private_network, libvirt__network_name: ENV["LIBVIRT__NETWORK_NAME"], ip: ENV["IP_NODE_#{idx}"]
    machine.vm.network "public_network", :dev => 'br0', :type => 'bridge'
  else
    machine.vm.network :private_network, ip: "10.13.37.#{10 + idx}"
  end
end

def configure_triggers(machine, idx)

  machine.trigger.after :up, :provision do |trigger|
    trigger.warn = "Saving this machine public ip in #{ENV['VM_PREFIX_NAME']}_public_ip"
    trigger.run_remote = { inline: "echo $(hostname): $(ip addr show eth2 | grep \"inet\\b\" | head -n1 | awk '{print $2}' | cut -d/ -f1) >> /vagrant/#{ENV['VM_PREFIX_NAME']}_public_ip" }
  end
  machine.trigger.before :destroy do |trigger|
    trigger.warn = "Deleting this machine public ip from #{ENV['VM_PREFIX_NAME']}_public_ip"
    trigger.run = { inline: "sed -i \"/#{idx}/d\" #{ENV['VM_PREFIX_NAME']}_public_ip" }
  end

end

Vagrant.configure("2") do |config|
  unless Vagrant.has_plugin?("vagrant-bindfs")
    abort 'Missing bindfs plugin! Please install using vagrant plugin install vagrant-bindfs'
  end

  config.vm.box = "hawk/leap-15.0-ha"
  config.vm.box_version = "1.0.8"
  config.vm.box_check_update = true
  config.ssh.insert_key = false

  # Change hacluster user's shell from nologin to /bin/bash to avoid issues with bindfs
  config.vm.provision "shell", inline: "chsh -s /bin/bash hacluster"

  config.vm.synced_folder ".", "/vagrant", type: "nfs", nfs_version: "4", nfs_udp: false, mount_options: ["rw", "noatime", "async"]
  config.bindfs.bind_folder "/vagrant", "/vagrant", force_user: "hacluster", force_group: "haclient", perms: "u=rwX:g=rwXD:o=rXD", after: :provision

  # Provision the machines using Salt
  config.vm.synced_folder "salt/salt", "/srv/salt"
  config.vm.provision :salt do |salt|
    salt.masterless = true
    salt.minion_config = "salt/etc/minion"
    salt.bootstrap_script = "salt/bootstrap-salt.sh"
    salt.install_master = false
    salt.run_highstate = true
    salt.verbose = true
    salt.colorize = true
    salt.no_minion = true
    # Optional: Consume pillar data from the configue file
    if defined?(GC)
      salt.pillar({
        "configure_routes" => true,
        "routes_config" => ENV["ROUTES_CONFIG"],
        "ip_node_0" => ENV["IP_NODE_0"],
        "ip_node_1" => ENV["IP_NODE_1"],
        "ip_node_2" => ENV["IP_NODE_2"],
        "ip_vip" => ENV["IP_VIP"],
        "ip_bundle_1" => ENV["IP_BUNDLE_1"],
        "ip_bundle_2" => ENV["IP_BUNDLE_2"]
      })
    else
      salt.pillar({
        "configure_routes" => false,
        "routes_config" => "",
        "ip_node_0" => "10.13.37.10",
        "ip_node_1" => "10.13.37.11",
        "ip_node_2" => "10.13.37.12",
        "ip_vip" => "10.13.37.20",
        "ip_bundle_1" => "10.13.37.13",
        "ip_bundle_2" => "10.13.37.100"
      })
    end
 end

  config.vm.define "webui", primary: true do |machine|
    machine.vm.hostname = "webui"
    machine.vm.network :forwarded_port, host_ip: host_bind_address, guest: 3000, host: 3000
    machine.vm.network :forwarded_port, host_ip: host_bind_address, guest: 8808, host: 8808
    configure_machine machine, 0, ["base", "webui"], ENV["VM_MEM"] || 2608, ENV["VM_CPU"] || 2
    configure_triggers(machine, "webui") if defined?(GC)
  end

  1.upto(2).each do |i|
    config.vm.define "node#{i}", autostart: true do |machine|
      machine.vm.hostname = "node#{i}"
      configure_machine machine, i, ["base", "node"], ENV["VM_MEM"] || 768, ENV["VM_CPU"] || 1
      configure_triggers(machine, "node#{i}") if defined?(GC)
    end
  end

end
