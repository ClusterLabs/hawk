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

class Tag < Record
  attribute :id, String
  attribute :refs, Array[String]

  validates :id,
    presence: { message: _("Tag ID is required") },
    format: { with: /\A[a-zA-Z0-9_-]+\z/, message: _("Invalid Tag ID") }

  validate do |record|
    # TODO(must): Ensure refs are sanitized
    errors.add :refs, _("No Tag resources specified") if record.refs.empty?
  end


  def mapping
    self.class.mapping
  end

  class << self
    def instantiate(xml)
      record = allocate

      record.refs = xml.elements.collect("obj_ref") do |el|
        el.attributes["id"]
      end

      record
    end

    def cib_type
      :tag
    end

    def mapping
      @mapping ||= {}
    end
  end

  protected

  def update
    unless self.class.exists?(self.id, self.class.cib_type_write)
      errors.add :base, _("The ID \"%{id}\" does not exist") % { id: self.id }
      return false
    end

    begin
      Invoker.instance.cibadmin_replace xml.to_s
    rescue NotFoundError, SecurityError, RuntimeError => e
      errors.add :base, e.message
      return false
    end

    true
  end

  def shell_syntax
    [].tap do |cmd|
      cmd.push "tag #{id}"

      refs.each do |ref|
        cmd.push ref
      end
    end.join(" ")
  end
end
