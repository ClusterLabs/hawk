#
# Cookbook Name:: hawk
# Attributes:: webui
#
# Copyright 2017, SUSE LLC
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

default["hawk"]["webui"]["ruby_version"] = "2.4" # Set to node["languages"]["ruby"]["version"] if you want to use default system version

default["hawk"]["webui"]["packages"] = [
  # Production dependencies
  "ruby#{default["hawk"]["webui"]["ruby_version"].to_f}-rubygem-rails-5.1",
  "ruby#{default["hawk"]["webui"]["ruby_version"].to_f}-rubygem-puma",
  "ruby#{default["hawk"]["webui"]["ruby_version"].to_f}-rubygem-sass-rails-5_0",
  "ruby#{default["hawk"]["webui"]["ruby_version"].to_f}-rubygem-virtus",
  "ruby#{default["hawk"]["webui"]["ruby_version"].to_f}-rubygem-js-routes",
  "ruby#{default["hawk"]["webui"]["ruby_version"].to_f}-rubygem-tilt",
  "ruby#{default["hawk"]["webui"]["ruby_version"].to_f}-rubygem-fast_gettext",
  "ruby#{default["hawk"]["webui"]["ruby_version"].to_f}-rubygem-gettext_i18n_rails",
  "ruby#{default["hawk"]["webui"]["ruby_version"].to_f}-rubygem-gettext_i18n_rails_js",
  "ruby#{default["hawk"]["webui"]["ruby_version"].to_f}-rubygem-sprockets",
  "ruby#{default["hawk"]["webui"]["ruby_version"].to_f}-rubygem-kramdown",

  # Development dependencies
  "ruby#{default["hawk"]["webui"]["ruby_version"].to_f}-rubygem-web-console",
  "ruby#{default["hawk"]["webui"]["ruby_version"].to_f}-rubygem-spring",
  "ruby#{default["hawk"]["webui"]["ruby_version"].to_f}-rubygem-uglifier",
  "ruby#{default["hawk"]["webui"]["ruby_version"].to_f}-rubygem-gettext",

  # Testing dependencies
  #"ruby#{default["hawk"]["webui"]["ruby_version"].to_f}-rubygem-rubocop",
  #"ruby#{default["hawk"]["webui"]["ruby_version"].to_f}-rubygem-brakeman",
  #"ruby#{default["hawk"]["webui"]["ruby_version"].to_f}-rubygem-rspec-rails",

  "git-core",

  "hawk2",
  "fence-agents",
  "ha-cluster-bootstrap",

  "apache2",
  "haproxy",

  "glib2-devel",
  "libxml2-devel",
  "pam-devel",
  "libpacemaker-devel",

  # debug stonith agents
  "libglue-devel",

  "drbd",
  "drbd-utils"
]

default["hawk"]["webui"]["targets"] = %w(
  clean
  tools/hawk_chkpwd
  tools/hawk_monitor
  tools/hawk_invoke
  tools/install
)

default["hawk"]["webui"]["haproxy_cfg"] = "/etc/haproxy/haproxy.cfg"
default["hawk"]["webui"]["apache_port"] = "sed -i 's/^Listen 80$/Listen 8000/g' /etc/apache2/listen.conf"
default["hawk"]["webui"]["apache_index"] = "/srv/www/htdocs/index.html"
default["hawk"]["webui"]["init_check"] = "systemctl -q is-active corosync.service"
default["hawk"]["webui"]["initial_cib"] = "/root/crm-initial.conf"

if node["virtualization"]["system"] == "kvm" then
  default["hawk"]["webui"]["init_command"] = "ha-cluster-init -i eth1 -y -t ocfs2 -p /dev/vdb"
else
  default["hawk"]["webui"]["init_command"] = "ha-cluster-init -i eth1 -y -t ocfs2 -p /dev/sdb"
end
