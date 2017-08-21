#
# Cookbook Name:: hawk
# Attributes:: default
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

case node["platform_family"]
when "suse"
  repo = case node["platform_version"]
  when /\A13\.\d+\z/
    "openSUSE_#{node["platform_version"]}"
  when /\A42\.\d+\z/
    "openSUSE_Leap_#{node["platform_version"]}"
  when /\A\d{8}\z/
    "openSUSE_Tumbleweed"
  else
    raise "Unsupported SUSE version"
  end

  # network:ha-clustering:Factory
  default["hawk"]["zypper"]["network-ha-clustering"]["enabled"] = true
  default["hawk"]["zypper"]["network-ha-clustering"]["alias"] = "network-ha-clustering"
  default["hawk"]["zypper"]["network-ha-clustering"]["title"] = "Network HA Clustering"
  default["hawk"]["zypper"]["network-ha-clustering"]["repo"] = "http://download.opensuse.org/repositories/network:/ha-clustering:/Factory/#{repo}/"
  default["hawk"]["zypper"]["network-ha-clustering"]["key"] = "#{node["hawk"]["zypper"]["network-ha-clustering"]["repo"]}repodata/repomd.xml.key"

  # devel:languages:ruby:extensions
  default["hawk"]["zypper"]["rubyext"]["enabled"] = true
  default["hawk"]["zypper"]["rubyext"]["alias"] = "rubyext"
  default["hawk"]["zypper"]["rubyext"]["title"] = "Ruby extensions"
  default["hawk"]["zypper"]["rubyext"]["repo"] = "http://download.opensuse.org/repositories/devel:/languages:/ruby:/extensions/#{repo}/"
  default["hawk"]["zypper"]["rubyext"]["key"] = "#{node["hawk"]["zypper"]["rubyext"]["repo"]}repodata/repomd.xml.key"

  # home:darix:apps
  default["hawk"]["zypper"]["darix"]["enabled"] = true
  default["hawk"]["zypper"]["darix"]["alias"] = "darix"
  default["hawk"]["zypper"]["darix"]["title"] = "Darix Repo"
  default["hawk"]["zypper"]["darix"]["repo"] = "http://download.opensuse.org/repositories/home:/darix:/apps/#{repo}/"
  default["hawk"]["zypper"]["darix"]["key"] = "#{node["hawk"]["zypper"]["darix"]["repo"]}repodata/repomd.xml.key"

  # List of repos to add
  default["hawk"]["zypper"]["repo_list"] = ["network-ha-clustering", "rubyext", "darix"]
end
