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
  "ruby2.4-rubygem-rails-5.1",
  "ruby2.4-rubygem-puma",
  "ruby2.4-rubygem-sass-rails-5_0",
  "ruby2.4-rubygem-virtus",
  "ruby2.4-rubygem-js-routes",
  "ruby2.4-rubygem-tilt",
  "ruby2.4-rubygem-fast_gettext",
  "ruby2.4-rubygem-gettext_i18n_rails",
  "ruby2.4-rubygem-gettext_i18n_rails_js",
  "ruby2.4-rubygem-sprockets",
  "ruby2.4-rubygem-kramdown",

  # Development dependencies
  "ruby2.4-rubygem-web-console",
  "ruby2.4-rubygem-spring",
  "ruby2.4-rubygem-uglifier",
  "ruby2.4-rubygem-gettext",

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
