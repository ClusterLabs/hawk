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
  attribute :https, Boolean
  attribute :port, Integer
  attribute :interval, Integer

  validates :name, presence: true
  validates :host, presence: true
  validates :port, presence: true, numericality: { only_integer: true, greater_than: 0, less_than: 65536 }
  validates :interval, presence: true, numericality: { only_integer: true, greater_than: 0 }

  def initialize(attrs = nil)
    super
    if self.new_record?
      self.https = (self.https.nil? ? true : self.https)
      self.port = self.port || 7630
      self.interval = self.interval || 30
    end
  end

  def to_hash
    {"name" => @name,
     "host" => @host,
     "https" => @https,
     "port" => @port,
     "interval" => @interval
    }
  end

  def to_json
    self.to_hash.to_json
  end

  protected

  def create
    fname = "#{Rails.root}/tmp/dashboard.js"
    if File.exists?(fname)
      Rails.logger.info "Reading #{fname}"
      clusters = JSON.parse(File.read(fname))
    else
      Rails.logger.info "Creating #{fname}"
      clusters = {}
    end
    clusters[@name] = self.to_hash
    Rails.logger.info "Writing #{fname}..."
    File.open(fname, "w") { |f| f.write(JSON.pretty_generate(clusters)) }
    Rails.logger.info "chmod 0660 #{fname}..."
    File.chmod(0660, fname)
    Rails.logger.info "Copy #{fname}..."
    ret = Invoker.instance.crm("cluster", "copy", fname)
    Rails.logger.info "Copy returned #{ret}"
    ret
  end

  def update
    create
  end

  class << self
    def parse(data)
      return Cluster.new(
               name: data['name'],
               host: data['host'],
               https: data['https'],
               port: data['port'],
               interval: data['interval']
             )
    end

    def all
      fname = "#{Rails.root}/tmp/dashboard.js"
      return [] unless File.exists?(fname)
      clusters = []
      JSON.parse(File.read(fname)).each do |id, data|
        clusters << parse(data)
      end
      clusters
    end

    def remove(name)
      fname = "#{Rails.root}/tmp/dashboard.js"
      return true unless File.exists?(fname)
      clusters = JSON.parse(File.read(fname))
      clusters = clusters.delete_if {|key, value| key == name }
      File.open(fname, "w") { |f| f.write(JSON.pretty_generate(clusters)) }
      File.chmod(0660, fname)
      Invoker.instance.crm("cluster", "copy", fname)
    end
  end
end
