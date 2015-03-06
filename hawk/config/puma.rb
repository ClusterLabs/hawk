#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2013 SUSE LLC, All Rights Reserved.
#
# Author: Tim Serong <tserong@suse.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it would be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Further, this software is distributed without any warranty that it is
# free of the rightful claim of any third person regarding infringement
# or the like.  Any license provided herein, whether implied or
# otherwise, applies only to this software file.  Patent licenses, if
# any, provided herein do not apply to combinations of this program with
# other software, or any other product whatsoever.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston MA 02111-1307, USA.
#
#======================================================================

ROOT = File.expand_path("../../", __FILE__)
ENVIRONMENT = ENV["HAWK_ENV"] || "production"

THREADS = ENV["HAWK_THREADS"] || 16
WORKERS = ENV["HAWK_WORKERS"] || 3

LISTEN = ENV["HAWK_LISTEN"] || "0.0.0.0"
PORT = ENV["HAWK_PORT"] || "7630"

KEY = ENV["HAWK_KEY"] || "/etc/ssl/certs/hawk.key"
CERT = ENV["HAWK_CERT"] || "/etc/ssl/certs/hawk.pem"

directory ROOT
environment ENVIRONMENT

tag "hawk"

quiet

daemonize false
prune_bundler false

threads 0, THREADS

workers WORKERS
worker_timeout 60

pidfile File.join(ROOT, "tmp", "pids", "puma.pid")
state_path File.join(ROOT, "tmp", "pids", "puma.state")

ssl_bind LISTEN, PORT, {
  cert: CERT,
  key: KEY
}

[
  "tmp/pids",
  "tmp/sessions",
  "tmp/sockets",
  "tmp/cache"
].each do |name|
  FileUtils.mkdir_p File.join(ROOT, name)
end
