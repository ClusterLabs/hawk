# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

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
      Rails.logger.debug "Reading #{fname}"
      clusters = JSON.parse(File.read(fname))
    else
      Rails.logger.debug "Creating #{fname}"
      clusters = {}
    end
    clusters[@name] = self.to_hash
    Rails.logger.debug "Writing #{fname}..."
    File.open(fname, "w") { |f| f.write(JSON.pretty_generate(clusters)) }
    Rails.logger.debug "chmod 0660 #{fname}..."
    File.chmod(0660, fname)
    Rails.logger.debug "Copy #{fname}..."
    ret = Invoker.instance.crm("cluster", "copy", fname)
    Rails.logger.debug "Copy returned #{ret}"
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
      Rails.logger.debug "remove: Removing #{name}..."
      fname = "#{Rails.root}/tmp/dashboard.js"
      return true unless File.exists?(fname)
      clusters = JSON.parse(File.read(fname))
      clusters = clusters.delete_if {|key, value| key == name }
      Rails.logger.debug "remove: Writing #{fname}..."
      File.open(fname, "w") { |f| f.write(JSON.pretty_generate(clusters)) }
      File.chmod(0660, fname)
      ret = Invoker.instance.crm("cluster", "copy", fname)
      Rails.logger.debug "remove: Copy returned #{ret}"
      ret
    end
  end
end
