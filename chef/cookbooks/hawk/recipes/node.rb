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

ruby_block "webui_check" do
  block do
    require "net/ssh"
    require "timeout"

    begin
      Timeout.timeout(600) do
        while true
          exit_code = 100

          begin
            Net::SSH.start node["hawk"]["node"]["ssh_host"], "vagrant", password: "vagrant", paranoid: false do |ssh|
              ssh.open_channel do |channel|
                channel.exec(node["hawk"]["node"]["ssh_check"]) do |ch, success|
                  unless success
                    Chef::Log.info "Failed to execute cluster check!"
                  end

                  channel.on_request("exit-status") do |ch, data|
                    exit_code = data.read_long
                  end
                end
              end
            end
          rescue Errno::EHOSTUNREACH => e
            Chef::Log.info "Waiting for webui to become available..."
          end

          case
          when exit_code == 0
            break
          when exit_code >= 1
            Chef::Log.info "Waiting for webui cluster setup..."
          end

          sleep 10
        end
      end
    rescue Timeout::Error
      raise "Cluster setup on webui timed out!"
    end
  end

  action :run
end

case node["platform_family"]
when "suse"
  include_recipe "zypper"

  zypper_repository node["hawk"]["zypper"]["alias"] do
    uri node["hawk"]["zypper"]["repo"]
    key node["hawk"]["zypper"]["key"]
    title node["hawk"]["zypper"]["title"]

    action [:add, :refresh]

    only_if do
      node["hawk"]["zypper"]["enabled"]
    end
  end
end

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

template node["hawk"]["node"]["apache_index"] do
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
