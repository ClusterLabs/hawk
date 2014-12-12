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

include_recipe "ruby"
include_recipe "foreman"

node["hawk"]["webui"]["packages"].each do |name|
  package name do
    action :install
  end
end

node["hawk"]["webui"]["targets"].each do |name|
  bash "hawk_make_#{name.gsub("/", "_")}" do
    user "root"
    cwd "/vagrant"

    code <<-EOH
      make WITHIN_VAGRANT=1 WWW_BASE=/vagrant #{name}
    EOH
  end
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

group "haclient" do
  members %w(vagrant)
  append true

  action :manage
end

foreman_app "/vagrant/hawk" do
  app "hawk-development"
  procfile "/home/vagrant/.hawkproc"

  user "vagrant"
  group "users"

  port 3000

  content(
    web: "bundle exec script/rails server"
  )
end

service "hawk-development" do
  service_name "hawk-development.target"
  action [:enable, :start]
end

crm_conf = node["hawk"]["webui"]["initial_cib"]
template crm_conf do
  source "crm-initial.conf.erb"
  owner "root"
  group "root"
  mode 0600
end

execute "crm initial configuration" do
  user "root"
  command "crm configure load update #{crm_conf}"
end
