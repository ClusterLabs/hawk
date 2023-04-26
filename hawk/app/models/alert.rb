# coding: utf-8
# Copyright (c) 2016 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license.
require 'invoker'

class Alert < Resource
  attribute :path, String
  attribute :recipients, Array[Recipient]

  validates :path, presence: { message: _("Path is required") }
  validate :path_must_exist, :path_must_exist

  def mapping
    {}.tap do |m|
      m[:meta] = {
        "timeout" => {
          type: "string",
          default: "30s",
          longdesc: _("If the alert agent does not complete within this amount of time, it will be terminated.")
        },
        "timestamp-format" => {
          type: "string",
          default: "%H:%M:%S.%06N",
          longdesc: _("Format the cluster will use when sending the event’s timestamp to the agent. This is a string as used with the date(1) command.")
        }
      }
      m[:params] = {}.tap do |p|
        params.map do |key, _|
          p[key] = {
            type: "string",
            default: "",
            longdesc: ""
          }
        end
      end
    end
  end

  class << self
    def all
      super.select do |record|
        record.is_a? self
      end
    end

    def instantiate(xml)
      record = allocate
      record.id = xml.attributes["id"] || ""
      record.path = xml.attributes["path"] || ""

      record.params = if xml.elements["instance_attributes"]
        vals = xml.elements["instance_attributes"].elements.collect do |el|
          [ el.attributes["name"], el.attributes["value"] ]
        end
        Hash[vals]
      else
        {}
      end

      record.meta = if xml.elements["meta_attributes"]
        vals = xml.elements["meta_attributes"].elements.collect do |el|
          [ el.attributes["name"], el.attributes["value"] ]
        end
        Hash[vals]
      else
        {}
      end

      record.recipients = [].tap do |recipients|
        xml.elements.each('recipient') do |r|
          recipient = Recipient.new
          recipient.id = r.attributes["id"]
          recipient.value = r.attributes["value"]
          recipient.params = if r.elements["instance_attributes"]
                               vals = r.elements["instance_attributes"].elements.collect do |el|
                                 [ el.attributes["name"], el.attributes["value"] ]
                               end
                               Hash[vals]
                             else
                               {}
                             end
          recipient.meta = if r.elements["meta_attributes"]
                             vals = r.elements["meta_attributes"].elements.collect do |el|
                               [ el.attributes["name"], el.attributes["value"] ]
                             end
                             Hash[vals]
                           else
                             {}
                           end
          recipients << recipient
        end
      end
      record
    end

    def cib_type
      :alert
    end
  end

  protected

  def path_must_exist
    unless File.exist?(path) or File.symlink?(path)
      errors.add(:path, "Path must be an existing file: File not found")
    end
  end

  def shell_syntax
    [].tap do |cmd|
      cmd.push "alert #{id} #{path.shellescape}"

      unless params.empty?
        cmd.push "attributes"
        params.each { |key, value| cmd.push [ key, value.shellescape ].join("=") }
      end

      unless meta.empty?
        cmd.push "meta"
        meta.each { |key, value| cmd.push [ key, value.shellescape ].join("=") }
      end

      recipients.each do |recipient|
        cmd.push "to { #{recipient.value.shellescape}"

        unless recipient.params.empty?
          cmd.push "attributes"
          recipient.params.each { |key, value| cmd.push [ key, value.shellescape ].join("=") }
        end

        unless recipient.meta.empty?
          cmd.push "meta"
          recipient.meta.each { |key, value| cmd.push [ key, value.shellescape ].join("=") }
        end

        cmd.push "}"
      end
    end.join(" ")
  end
end
