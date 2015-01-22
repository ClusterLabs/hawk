#
# Cookbook Name:: hawk
# Recipe:: node
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

node["hawk"]["node"]["packages"].each do |name|
  package name do
    action :install
  end
end

template node["hawk"]["node"]["haproxy_cfg"] do
  source "haproxy.cfg.erb"
  owner "root"
  group "root"
  mode 0644

  variables(
    node["hawk"]["node"]
  )

  not_if do
    node["hawk"]["node"]["haproxy_cfg"].empty?
  end
end

bash "apache_port" do
  user "root"
  cwd "/etc/apache2"

  code node["hawk"]["node"]["apache_port"]
end

bash "hawk_join" do
  user "root"
  cwd "/vagrant"

  code node["hawk"]["node"]["join_command"]

  only_if do
    Mixlib::ShellOut.new(
      node["hawk"]["node"]["join_check"]
    ).run_command.error?
  end
end
