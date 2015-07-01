#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2015 SUSE LLC, All Rights Reserved.
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

require 'json'

class Cluster < Tableless
  attribute :name, String
  attribute :host, String
  attribute :interval, Integer

  validates :name, presence: true
  validates :host, presence: true
  validates :interval, presence: true

  def to_hash
    {"name" => @name,
     "host" => @host,
     "interval" => @interval
    }
  end

  def to_json
    self.to_hash.to_json
  end

  protected

  def create
    clustersfile = "#{Rails.root}/tmp/dashboard.js"
    if File.exists?(clustersfile)
      clusters = JSON.parse(File.read(clustersfile))
    else
      clusters = {}
    end
    clusters[@name] = self.to_hash
    File.open(clustersfile, "w") { |f| f.write(JSON.pretty_generate(clusters)) }
    File.chmod(0660, clustersfile)
    Invoker.instance.crm("cluster", "copy", clustersfile)
  end

  def update
    create
  end

  class << self
    def parse(data)
      return Cluster.new(
               name: data['name'],
               host: data['host'],
               interval: data['interval']
             )
    end

    def all
      clustersfile = "#{Rails.root}/tmp/dashboard.js"
      return [Cluster.new(name: Socket.gethostname,
                          host: "0.0.0.0",
                          interval: 10
                         )] unless File.exists?(clustersfile)
      clusters = []
      JSON.parse(File.read(clustersfile)).each do |id, data|
        clusters << parse(data)
      end
      clusters
    end

    def remove(name)
      clustersfile = "#{Rails.root}/tmp/dashboard.js"
      return true unless File.exists?(clustersfile)
      clusters = JSON.parse(File.read(clustersfile))
      clusters = clusters.delete_if {|key, value| key == name }
      File.open(clustersfile, "w") { |f| f.write(JSON.pretty_generate(clusters)) }
      File.chmod(0660, clustersfile)
      Invoker.instance.crm("cluster", "copy", clustersfile)
    end
  end
end
