# -*- mode: ruby -*-
# vi: set ft=ruby :

$PATCH_CHEF = <<SCRIPT
cd /opt/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-11.16.2/

if [[ ! -f /root/.chef_patch_2052 ]]; then
  wget -q -O - https://github.com/opscode/chef/pull/2052.patch | patch -p1 -f
  touch /root/.chef_patch_2052
fi

if [[ ! -f /root/.chef_patch_2187 ]]; then
  wget -q -O - https://github.com/opscode/chef/pull/2187.patch | patch -p1 -f
  touch /root/.chef_patch_2187
fi
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "hawk"
  config.vm.box_url = "http://w3.suse.de/~tboerger/vagrant/sles12-sp0-minimal-virtualbox-0.0.1.box"

  config.librarian_chef.cheffile_dir = "chef"
  config.omnibus.chef_version = "11.16.2"

  # A temporary fix until chef gets prepared for SLES 12
  config.vm.provision "shell", inline: $PATCH_CHEF

  config.vm.define "webui", default: true do |machine|
    machine.vm.hostname = "webui.hawk.suse.com"

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
      provider.memory = 2048
      provider.cpus = 4

      provider.name = "hawk-webui"
    end
  end

  1.upto(3).each do |i|
    config.vm.define "node#{i}" do |machine|
      machine.vm.hostname = "node#{i}.hawk.suse.com"

      machine.vm.network "forwarded_port", guest: 22, host: 3022 + (i * 100)
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
