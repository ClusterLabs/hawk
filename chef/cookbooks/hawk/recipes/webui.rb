#
# Cookbook Name:: hawk
# Recipe:: webui
#
# Copyright 2014, SUSE LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

bash "probe_watchdog" do
  user "root"
  cwd "/"
  code "modprobe softdog"
end

template "/etc/modules-load.d/softdog.conf" do
  source "softdog.conf"
  owner "root"
  group "root"
  mode 0644
end

case node["platform_family"]
when "suse"
  include_recipe "zypper"
  node["hawk"]["zypper"]["repo_list"].each do |repo_name|
    zypper_repository node["hawk"]["zypper"][repo_name]["alias"] do
      uri node["hawk"]["zypper"][repo_name]["repo"]
      key node["hawk"]["zypper"][repo_name]["key"]
      title node["hawk"]["zypper"][repo_name]["title"]

      action [:add, :refresh]

      only_if do
        node["hawk"]["zypper"][repo_name]["enabled"]
      end
    end
  end
end

# Install rbenv for user "vagrant"
rbenv_user_install 'vagrant'

rbenv_plugin 'ruby-build' do
  git_url 'https://github.com/rbenv/ruby-build.git'
  user 'vagrant'
end

rbenv_ruby '2.4.1' do
  user 'vagrant'
end

rbenv_global '2.4.1' do
  user 'vagrant'
end

rbenv_rehash 'rehash' do
  user 'vagrant'
end


node["hawk"]["webui"]["packages"].each do |name|
  package name do
    action :install
  end
end

ENV['PKG_CONFIG_PATH'] = '/usr/lib64/pkgconfig'

node["hawk"]["webui"]["targets"].each do |name|
  bash "hawk_make_#{name.gsub("/", "_")}" do
    user "root"
    cwd "/vagrant"

    code <<-EOH
      make WITHIN_VAGRANT=1 WWW_BASE=/vagrant #{name}
    EOH
  end
end

template "/etc/drbd.d/global_common.conf" do
  source "global_common.conf.erb"
  owner "root"
  group "root"
  mode 0644
end

template "/etc/drbd.d/r0.res" do
  source "r0.res.erb"
  owner "root"
  group "root"
  mode 0644
end

bash "DRBD disk creation" do
  user "root"

  code <<-EOF
drbdadm dump all
drbdadm create-md r0
drbdadm up r0
drbdadm new-current-uuid --clear-bitmap r0/0
drbdadm primary --force r0
mkfs.ext4 /dev/drbd0
EOF
end

bash "hawk_init" do
  user "root"
  cwd "/vagrant"

  code node["hawk"]["webui"]["init_command"]

  only_if do
    Mixlib::ShellOut.new(
      node["hawk"]["webui"]["init_check"]
    ).run_command.error?
  end
end

bash "increase_numslots_ocfs2" do
  user "root"

  code <<-EOH
if [ -e /dev/sdb2 ]; then
  if [ "$(tunefs.ocfs2 -Q "%N" /dev/sdb2)" != "4" ]; then
    crm -w resource stop c-clusterfs
    tunefs.ocfs2 -N 4 /dev/sdb2
    crm -w resource start c-clusterfs
  fi
else
  if [ "$(tunefs.ocfs2 -Q "%N" /dev/vdb2)" != "4" ]; then
    crm -w resource stop c-clusterfs
    tunefs.ocfs2 -N 4 /dev/vdb2
    crm -w resource start c-clusterfs
  fi
fi
EOH
end


group "haclient" do
  members %w(vagrant)
  append true

  action :manage
end

template node["hawk"]["webui"]["haproxy_cfg"] do
  source "haproxy.cfg.erb"
  owner "root"
  group "root"
  mode 0644

  variables(
    node["hawk"]["webui"]
  )

  not_if do
    node["hawk"]["webui"]["haproxy_cfg"].empty?
  end
end

template node["hawk"]["webui"]["apache_index"] do
  source "index.html.erb"
  owner "root"
  group "root"
  mode 0644
  variables(
    :hostname => node[:hostname]
  )
end

bash "apache_port" do
  user "root"
  cwd "/etc/apache2"

  code node["hawk"]["webui"]["apache_port"]
end


template node["hawk"]["webui"]["initial_cib"] do
  source "crm-initial.conf.erb"
  owner "root"
  group "root"
  mode 0600
end

execute "crm initial configuration" do
  user "root"
  command "crm configure load update #{node["hawk"]["webui"]["initial_cib"]}"
end

execute "crm drbd configuration" do
  user "root"
  command "crm script run drbd id=DRBD drbd_resource=r0"
end

template "/etc/systemd/system/hawk-development.service" do
   source "systemd.service.erb"
   owner "root"
   group "root"
   mode 0644
end

file '/home/vagrant/.profile' do
  content <<-EOF
    test -z "$PROFILEREAD" && . /etc/profile || true
    export PATH=/vagrant/hawk/bin:$PATH
  EOF
end

service "hawk-development" do
  action [:enable, :start]
end
