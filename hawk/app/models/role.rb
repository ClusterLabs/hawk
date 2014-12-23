#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2011-2014 SUSE LLC, All Rights Reserved.
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

class Role < Record
  attribute :id, String
  attribute :rules, RuleCollection[Rule]

  validates :id,
    presence: { message: _('Role ID is required') },
    format: { with: /^[a-zA-Z0-9_-]+$/, message: _('Invalid Role ID') }

  def initialize(*args)
    rules.build
    super
  end

  def rules_attributes=(attrs)
    @rules = RuleCollection.new

    attrs.each do |key, values|
      @rules.push Rule.new(values)
    end
  end

  def rules
    @rules ||= RuleCollection.new
  end

  def valid?
    super & rules.valid?
  end

  protected

  def shell_syntax
    [].tap do |cmd|
      cmd.push "role #{id}"

      rules.each do |rule|
        cmd.push rule.right

        cmd.push "tag:#{rule.tag}" unless rule.tag.to_s.empty?
        cmd.push "ref:#{rule.ref}" unless rule.ref.to_s.empty?
        cmd.push "xpath:#{rule.xpath}" unless rule.xpath.to_s.empty?
        cmd.push "attribute:#{rule.attribute}" unless rule.attribute.to_s.empty?
      end
    end.join(' ')
  end

  class << self
    def instantiate(xml)
      record = allocate

      xml.elements.each do |elem|
        record.rules.build(
          right: elem.attributes['kind'],
          tag: elem.attributes['object-type'] || nil,
          ref: elem.attributes['reference'] || nil,
          xpath: elem.attributes['xpath'] || nil,
          attribute: elem.attributes['attribute'] || nil
        )
      end

      record
    end

    def cib_type
      :acl_role
    end
  end
end
