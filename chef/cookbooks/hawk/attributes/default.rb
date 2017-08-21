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

  default["hawk"]["zypper"]["enabled"] = true
  default["hawk"]["zypper"]["alias"] = "network-ha-clustering"
  default["hawk"]["zypper"]["title"] = "Network HA Clustering"
  default["hawk"]["zypper"]["repo"] = "http://download.opensuse.org/repositories/network:/ha-clustering:/Factory/#{repo}/"
  default["hawk"]["zypper"]["key"] = "#{node["hawk"]["zypper"]["repo"]}repodata/repomd.xml.key"

  default["hawk"]["zypper"]["nodejs_repo_alias"] = "devel:languages:nodejs"
  default["hawk"]["zypper"]["nodejs_repo_title"] = "devel:languages:nodejs"
  default["hawk"]["zypper"]["nodejs_repo"] = "http://download.opensuse.org/repositories/devel:/languages:/nodejs/#{repo}/"


end
