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

default["hawk"]["zypper"]["enabled"] = true
default["hawk"]["zypper"]["alias"] = "network-ha-clustering"
default["hawk"]["zypper"]["title"] = "Network HA Clustering"
default["hawk"]["zypper"]["repo"] = "http://download.opensuse.org/repositories/network:/ha-clustering:/Factory/openSUSE_#{node["platform_version"]}/"
default["hawk"]["zypper"]["key"] = "#{node["hawk"]["zypper"]["repo"]}repodata/repomd.xml.key"
