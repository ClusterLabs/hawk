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

class Template < Record
  attribute :id, String
  attribute :clazz, String, default: "ocf"
  attribute :provider, String
  attribute :type, String
  attribute :ops, Hash, default: {}
  attribute :params, Hash, default: {}
  attribute :meta, Hash, default: {}

  validates :id,
    presence: { message: _("Resource ID is required") },
    format: { with: /\A[a-zA-Z0-9_-]+\z/, message: _("Invalid Resource ID") }

  def mapping
    self.class.mapping
  end

  def template?
    true
  end

  def resource?
    false
  end

  class << self
    def instantiate(xml)
      record = allocate
      record.clazz = xml.attributes["class"] || ""
      record.provider = xml.attributes["provider"] || ""
      record.type = xml.attributes["type"] || ""

      record.params = if xml.elements["instance_attributes"]
        vals = xml.elements["instance_attributes"].elements.collect do |el|
          [
            el.attributes["name"],
            el.attributes["value"]
          ]
        end

        Hash[vals]
      else
        {}
      end

      record.meta = if xml.elements["meta_attributes"]
        vals = xml.elements["meta_attributes"].elements.collect do |el|
          [
            el.attributes["name"],
            el.attributes["value"]
          ]
        end

        Hash[vals]
      else
        {}
      end

      record.ops = if xml.elements["operations"]
        vals = xml.elements["operations"].elements.collect do |el|
          ops = el.attributes.collect do |name, value|
            next if ["id", "name"].include? name

            [
              name,
              value
            ]
          end.compact

          [
            el.attributes["name"],
            Hash[ops]
          ]
        end

        Hash[vals]
      else
        {}
      end

      record
    end

    def cib_type
      :template
    end











    def classes_and_providers
      PerRequestCache.fetch(:ra_classes_and_providers) {
        cp = {
          :r_classes   => [],
          :r_providers => {}
        }
        all_classes = %x[/usr/sbin/crm ra classes].split(/\n/).sort {|a,b| a.natcmp(b, true)}
        # Cheap hack to get rid of heartbeat class if there"s no RAs of that type present
        all_classes.delete("heartbeat") unless File.exists?("/etc/ha.d/resource.d")
        all_classes.each do |c|
          if m = c.match("(.*)/(.*)")
            c = m[1].strip
            cp[:r_providers][c] = m[2].strip.split(" ").sort {|a,b| a.natcmp(b, true)}
          end
          cp[:r_classes].push c
        end
        cp
      }
    end

    def types(c, p="")
      # TODO(should): Optimally this would be saved to a static variable,
      # e.g.: "@@r_types ||= Util.safe_x(...)", except that this lives for
      # the entire life of Hawk when run under lighttpd, which has two
      # problems:
      # 1) Unless we save it per-class-provider (@@r_types[c][p] ||= ...)
      #    it"s impossible to get the RA list for any combination of c/p
      #    except for the first time we call the function.
      # 2) Even if we fixed that, if a new RA is installed, Hawk still
      #    shows the old list.
      # This suggests the need for some sort of expiring cache of RAs,
      # which is a performance optimization we can worry about later...
      Util.safe_x("/usr/sbin/crm", "ra", "list", c, p).split(/\s+/).sort {|a,b| a.natcmp(b, true)}
    end

    def metadata(c, p, t)
      m = {
        :shortdesc => "",
        :longdesc => "",
        :parameters => {},
        :ops => {},
        :meta => {
          "allow-migrate" => {
            :type     => "boolean",
            :default  => "false"
          },
          "is-managed" => {
            :type     => "boolean",
            :default  => "true"
          },
          "maintenance" => {
            :type     => "boolean",
            :default  => "false"
          },
          "interval-origin" => {
            :type     => "integer",
            :default  => "0"
          },
          "migration-threshold" => {
            :type     => "integer",
            :default  => "0"
          },
          "priority" => {
            :type     => "integer",
            :default  => "0"
          },
          "multiple-active" => {
            :type     => "enum",
            :default  => "stop_start",
            :values   => [ "block", "stop_only", "stop_start" ]
          },
          "failure-timeout" => {
            :type     => "integer",
            :default  => "0"
          },
          "resource-stickiness" => {
            :type     => "integer",
            :default  => "0"
          },
          "target-role" => {
            :type     => "enum",
            :default  => "Started",
            :values   => [ "Started", "Stopped", "Master" ]
          },
          "restart-type" => {
            :type     => "enum",
            :default  => "ignore",
            :values   => [ "ignore", "restart" ]
          },
          "description" => {
            :type     => "string",
            :default  => ""
          }
        }
      }
      return m if c.empty? or t.empty?

      # crm_resource --show-metadata is good since at least pacemaker 1.1.8,
      # which we require now anyway (previously we were using lrmd_test with
      # a fallback to lrmadmin, but lrmd_test lives in cts and lrmadmin is gone)
      xml = REXML::Document.new(Util.safe_x("/usr/sbin/crm_resource", "--show-metadata",
                                            p.empty? ? "#{c}:#{t}" : "#{c}:#{p}:#{t}"))

      return m unless xml.root
      # TODO(should): select by language (en), likewise below
      m[:shortdesc] = Util.get_xml_text(xml.root.elements["shortdesc"])
      m[:longdesc]  = Util.get_xml_text(xml.root.elements["longdesc"])
      xml.elements.each("//parameter") do |e|
        m[:parameters][e.attributes["name"]] = {
          :shortdesc => Util.get_xml_text(e.elements["shortdesc"]),
          :longdesc  => Util.get_xml_text(e.elements["longdesc"]),
          :type     => e.elements["content"].attributes["type"],
          :default  => e.elements["content"].attributes["default"],
          :required => e.attributes["required"].to_i == 1 ? true : false
        }
      end
      xml.elements.each("//action") do |e|
        name = e.attributes["name"]
        m[:ops][name] = [] unless m[:ops][name]
        op = Hash[e.attributes.collect{|a| a.to_a}]
        op.delete "name"
        op.delete "depth"
        # There"s at least one case (ocf:ocfs2:o2cb) where the
        # monitor op doesn"t specify an interval, so we set a
        # "reasonable" default
        if name == "monitor" && !op.has_key?("interval")
          op["interval"] = "20"
        end
        m[:ops][name].push op
      end
      m
    end




















    def mapping
      # TODO(must): Are other meta attributes for primitive valid?
      @mapping ||= begin
        {

        }
      end
    end
  end

  protected

  def update
    unless self.class.exists?(self.id, self.class.cib_type_write)
      errors.add :base, _("The ID \"%{id}\" does not exist") % { id: self.id }
      return false
    end

    begin
      merge_operations(ops)
      merge_nvpairs("instance_attributes", params)
      merge_nvpairs("meta_attributes", meta)





      Rails.logger.debug(xml.inspect)
      raise xml.inspect





      Invoker.instance.cibadmin_replace xml.to_s
    rescue NotFoundError, SecurityError, RuntimeError => e
      errors.add :base, e.message
      return false
    end

    true
  end

  def shell_syntax
    [].tap do |cmd|
      # TODO(must): Ensure clazz, provider and type are sanitized
      cmd.push "rsc_template #{id}"

      cmd.push [
        clazz,
        provider,
        type
      ].reject(&:nil?).reject(&:empty?).join(":")

      unless params.empty?
        cmd.push "params"

        params.each do |key, value|
          cmd.push [
            key,
            value.shellescape
          ].join("=")
        end
      end

      unless ops.empty?
        cmd.push "params"

        ops.each do |op, instances|
          instances.each do |i, attrlist|
            cmd.push "op #{op}"

            attrlist.each do |key, value|
              cmd.push [
                key,
                value.shellescape
              ].join("=")
            end
          end
        end
      end

      unless meta.empty?
        cmd.push "meta"

        meta.each do |key, value|
          cmd.push [
            key,
            value.shellescape
          ].join("=")
        end
      end





      raise cmd.join(" ").inspect





    end.join(" ")
  end
end
