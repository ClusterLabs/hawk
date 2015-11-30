# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "webhippie/opensuse-13.2"
  config.vm.box_check_update = true
  config.ssh.insert_key = false

  #config.vm.synced_folder ".", "/vagrant", type: "nfs", mount_options: ["rw", "noatime", "async"]
  config.vm.synced_folder ".", "/vagrant"

  #unless Vagrant.has_plugin?("vagrant-bindfs")
  #  abort 'Missing bindfs plugin! Please install using vagrant plugin install vagrant-bindfs'
  #end

  #config.bindfs.bind_folder "/vagrant", "/vagrant",
  #                          force_user: "hacluster",
  #                          force_group: "haclient",
  #                          perms: "u=rwX:g=rwXD:o=rXD",
  #                          after: :provision

  config.vm.define "webui", primary: true do |machine|
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

    machine.vm.network :private_network,
      ip: "10.13.37.10"

    machine.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = ["chef/cookbooks"]
      chef.roles_path = ["chef/roles"]
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
      provider.graphics_port = 9200
    end
  end

  1.upto(3).each do |i|
    config.vm.define "node#{i}", autostart: false do |machine|
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

      machine.vm.network :private_network,
        ip: "10.13.37.#{10 + i}"

      machine.vm.provision :chef_solo do |chef|
        chef.cookbooks_path = ["chef/cookbooks"]
        chef.roles_path = ["chef/roles"]
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
        provider.graphics_port = 9200 + i
      end
    end
  end

  config.vm.provider :libvirt do |provider, override|
    provider.storage_pool_name = "default"
    provider.management_network_name = "vagrant"
  end
end
