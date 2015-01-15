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
  # Production dependencies
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-rails-4_2",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-puma",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-fast_gettext",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-gettext_i18n_rails",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-sprockets",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-tilt-1_4",

  # Development dependencies
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-gettext",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-web-console",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-spring",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-quiet_assets",

  # Current development fix
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-haml-rails",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-sass-rails",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-virtus",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-gettext_i18n_rails_js",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-js-routes",

  "hawk",
  "hawk-templates",
  "ha-cluster-bootstrap",
  "w3m",

  # Development dependencies

  "glib2-devel",
  "libxml2-devel",
  "pam-devel",
  "libpacemaker-devel",

  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-gettext",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-byebug",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-web-console",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-spring",
  "ruby#{node["languages"]["ruby"]["version"].to_f}-rubygem-quiet_assets",

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
default["hawk"]["webui"]["initial_cib"] = "/root/crm-initial.conf"
