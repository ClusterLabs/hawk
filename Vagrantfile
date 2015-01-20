# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "webhippie/opensuse-13.2"
  config.vm.box_check_update = true

  if Vagrant.has_plugin? "vagrant-librarian-chef"
    config.librarian_chef.enabled = true
    config.librarian_chef.cheffile_dir = "chef"
  end

  config.vm.define "webui", default: true do |machine|
    machine.vm.hostname = "webui"

    machine.vm.network :forwarded_port,
      host_ip: ENV['VAGRANT_INSECURE_FORWARDS'] =~ /^(y(es)?|true|on)$/i ?
        '*' : '127.0.0.1',
      guest: 22,
      host: 3022

    machine.vm.network :forwarded_port,
      host_ip: ENV['VAGRANT_INSECURE_FORWARDS'] =~ /^(y(es)?|true|on)$/i ?
        '*' : '127.0.0.1',
      guest: 3000,
      host: 3000

    machine.vm.network :forwarded_port,
      host_ip: ENV['VAGRANT_INSECURE_FORWARDS'] =~ /^(y(es)?|true|on)$/i ?
        '*' : '127.0.0.1',
      guest: 7630,
      host: 7630

    machine.vm.network "private_network",
      ip: "10.13.37.10"

    machine.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = ["chef/cookbooks", "chef/site"]
      chef.roles_path = "chef/roles"
      chef.custom_config_path = "chef/solo.rb"
      chef.synced_folder_type = "rsync"

      chef.add_role "base"
      chef.add_role "webui"
    end

    machine.vm.provider :virtualbox do |provider, override|
      provider.memory = 1024
      provider.cpus = 1
      provider.name = "hawk-webui"
    end

    machine.vm.provider :libvirt do |provider, override|
      provider.memory = 1024
      provider.cpus = 1
    end
  end

  1.upto(3).each do |i|
    config.vm.define "node#{i}" do |machine|
      machine.vm.hostname = "node#{i}"

      machine.vm.network :forwarded_port,
        host_ip: ENV['VAGRANT_INSECURE_FORWARDS'] =~ /^(y(es)?|true|on)$/i ?
          '*' : '127.0.0.1',
        guest: 22,
        host: 3022 + (i * 100)

      machine.vm.network :forwarded_port,
        host_ip: ENV['VAGRANT_INSECURE_FORWARDS'] =~ /^(y(es)?|true|on)$/i ?
          '*' : '127.0.0.1',
        guest: 7630,
        host: 7630 + i

      machine.vm.network "private_network",
        ip: "10.13.37.#{10 + i}"

      machine.vm.provision :chef_solo do |chef|
        chef.cookbooks_path = ["chef/cookbooks", "chef/site"]
        chef.roles_path = "chef/roles"
        chef.custom_config_path = "chef/solo.rb"
        chef.synced_folder_type = "rsync"

        chef.add_role "base"
        chef.add_role "node"
      end

      machine.vm.provider :virtualbox do |provider, override|
        provider.memory = 512
        provider.cpus = 1
        provider.name = "hawk-node#{i}"
      end

      machine.vm.provider :libvirt do |provider, override|
        provider.memory = 512
        provider.cpus = 1
      end
    end
  end

  config.vm.provider :libvirt do |provider, override|
    provider.storage_pool_name = "default"
    provider.management_network_name = "vagrant"

    override.vm.synced_folder ".", "/vagrant", type: "nfs"

    if Vagrant.has_plugin? "vagrant-bindfs"
      override.bindfs.bind_folder "/vagrant", "/vagrant",
        force_user: "vagrant",
        force_group: "users"
    end
  end

  config.vm.provider :virtualbox do |provider, override|
    override.vm.synced_folder ".", "/vagrant", type: "virtualbox"
  end
end
