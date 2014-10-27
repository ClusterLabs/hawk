#
# Cookbook Name:: hawk
# Attributes:: webui
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

default["hawk"]["webui"]["packages"] = [
  "rubygem-rails-3_2",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-fast_gettext",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-gettext_i18n_rails",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-gettext",

  "hawk",
  "hawk-templates",
  "ha-cluster-bootstrap",

  "glib2-devel",
  "libxml2-devel",
  "pam-devel",
  "libpacemaker-devel"
]

default["hawk"]["webui"]["targets"] = %w(
  clean
  tools/hawk_chkpwd
  tools/hawk_monitor
  tools/hawk_invoke
  tools/install
)

default["hawk"]["webui"]["init_command"] = "ha-cluster-init -i eth1 -y"
default["hawk"]["webui"]["init_check"] = "systemctl -q is-active corosync.service"
