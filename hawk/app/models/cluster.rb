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
      self.https = (https.nil? ? true : https)
      self.port = port || 7630
      self.interval = interval || 30
    end
  end

  def to_hash
    {
      "name" => @name,
      "host" => @host,
      "https" => @https,
      "port" => @port,
      "interval" => @interval
    }
  end

  def to_json
    to_hash.to_json
  end

  protected

  def create
    fname = "#{Rails.root}/tmp/dashboard.js"
    if File.exist? fname
      Rails.logger.debug "Reading #{fname}"
      clusters = JSON.parse(File.read(fname))
    else
      Rails.logger.debug "Creating #{fname}"
      clusters = {}
    end
    clusters[@name] = to_hash
    Cluster.cluster_copy clusters
  end

  def update
    create
  end

  class << self
    def parse(data)
      Cluster.new(
        name: data['name'],
        host: data['host'],
        https: (data['https'].nil? ? true : data['https']),
        port: data['port'] || 7630,
        interval: data['interval'] || 30
      )
    end

    def all
      fname = "#{Rails.root}/tmp/dashboard.js"
      return [] unless File.exist? fname
      clusters = []
      begin
        JSON.parse(File.read(fname)).each do |_, data|
          clusters << parse(data)
        end
      rescue Exception => e
        Rails.logger.debug "Error: #{e}"
      end
      clusters
    end

    def remove(name)
      Rails.logger.debug "remove: Removing #{name}..."
      fname = "#{Rails.root}/tmp/dashboard.js"
      return true unless File.exist?(fname)
      begin
        clusters = JSON.parse(File.read(fname))
        clusters = clusters.delete_if { |key, _| key == name }
        ret = cluster_copy clusters
        ["", ret, 1] if ret.is_a? String
        ["", "", 0]
      rescue Exception => e
        Rails.logger.debug "Remove cluster: #{e.message}"
        ["", e.message, 1]
      end
    end

    def cluster_copy(clusters)
      fname = "#{Rails.root}/tmp/dashboard.js"
      File.open(fname, "w") { |f| f.write(JSON.pretty_generate(clusters)) }
      File.chmod(0660, fname)
      out, err, rc = Util.capture3("crm", "cluster", "copy", fname)
      Rails.logger.debug "Copy: #{out} #{err} #{rc}"
      # always succeed here: we don't really care that much if the copy succeeded or not
      true
    rescue Exception => e
      Rails.logger.debug "Copy: #{e.message}"
      e.message
    end
  end
end
