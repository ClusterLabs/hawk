#
# Cookbook Name:: hawk
# Attributes:: node
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

default["hawk"]["node"]["packages"] = [
  "rubygem-rails-3_2",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-fast_gettext",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-gettext_i18n_rails",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-gettext",

  "hawk",
  "hawk-templates",
  "ha-cluster-bootstrap",

  "apache2",
  "haproxy"
]

default["hawk"]["node"]["haproxy_cfg"] = "/etc/haproxy/haproxy.cfg"
default["hawk"]["node"]["apache_port"] = "sed -i 's/^Listen 80$/Listen 8000/g' /etc/apache2/listen.conf"

default["hawk"]["node"]["join_command"] = "ha-cluster-join -c 10.13.37.10 -i eth1 -y"
default["hawk"]["node"]["join_check"] = "systemctl -q is-active corosync.service"

default["hawk"]["node"]["ssh_host"] = "10.13.37.10"
default["hawk"]["node"]["ssh_check"] = "/usr/sbin/crm_mon -1"
