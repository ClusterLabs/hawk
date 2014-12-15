# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "krig/opensuse-13.2"

  config.librarian_chef.cheffile_dir = "chef"

  config.vm.define "webui", default: true do |machine|
    machine.vm.hostname = "webui"

    machine.vm.network "forwarded_port", guest: 22, host: 3022
    machine.vm.network "forwarded_port", guest: 3000, host: 3000
    machine.vm.network "forwarded_port", guest: 7630, host: 7630
    machine.vm.network "private_network", ip: "10.13.37.10"

    machine.vm.synced_folder ".", "/vagrant", type: "virtualbox"

    machine.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = ["chef/cookbooks", "chef/site"]
      chef.roles_path = "chef/roles"
      chef.custom_config_path = "chef/solo.rb"
      chef.synced_folder_type = "virtualbox"

      chef.add_role "base"
      chef.add_role "webui"
    end

    machine.vm.provider :virtualbox do |provider, override|
      provider.memory = 512
      provider.cpus = 1

      provider.name = "hawk-webui"
    end
  end

  1.upto(3).each do |i|
    config.vm.define "node#{i}" do |machine|
      machine.vm.hostname = "node#{i}"

      machine.vm.network "forwarded_port", guest: 22, host: 3022 + (i * 100)
      machine.vm.network "forwarded_port", guest: 7630, host: 7630 + i
      machine.vm.network "private_network", ip: "10.13.37.#{10 + i}"

      machine.vm.synced_folder ".", "/vagrant", type: "virtualbox"

      machine.vm.provision :chef_solo do |chef|
        chef.cookbooks_path = ["chef/cookbooks", "chef/site"]
        chef.roles_path = "chef/roles"
        chef.custom_config_path = "chef/solo.rb"
        chef.synced_folder_type = "virtualbox"

        chef.add_role "base"
        chef.add_role "node"
      end

      machine.vm.provider :virtualbox do |provider, override|
        provider.memory = 512
        provider.cpus = 1

        provider.name = "hawk-node#{i}"
      end
    end
  end
end
