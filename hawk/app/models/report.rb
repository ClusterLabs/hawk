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

class Report
  attr_accessor :id
  attr_accessor :order

  attr_accessor :archive
  attr_accessor :from
  attr_accessor :until

  def initialize(attributes)
    attributes.each do |key, value|
      self.send(
        "#{key}=".to_sym,
        value
      )
    end
  end

  def delete
    self.archive.delete
  end

  def load!



  end

  def report_path
    self.class.report_path
  end

  class << self
    def parse(file)
      hash = Digest::SHA1.hexdigest(
        file.basename(".tar.bz2").to_s
      )

      match = file.basename.to_s.match(
        /(\d{4}-\d{2}-\d{2}_\d{2}:\d{2})/
      )

      order = [
        match[0],
        match[1]
      ].join("-")

      Report.new(
        id: hash,
        order: order,

        archive: file,
        from: DateTime.parse(match[0]),
        until: DateTime.parse(match[1])
      )
    end

    def find(id)
      file = report_file(id).dup

      if file
        record = parse(file)
        record.load!

        record
      else
        nil
      end
    end

    def all
      report_files.values.map do |file|
        parse(file)
      end.sort_by(&:order)
    end

    def report_files
      files = report_path.children.select do |file|
        if file.extname == ".bz2"
          file
        end
      end

      {}.tap do |result|
        files.each do |file|
          hash = Digest::SHA1.hexdigest(
            file.basename(".tar.bz2").to_s
          )

          result[hash] = file
        end
      end
    end

    def report_file(name)
      report_files[name]
    end

    def report_path
      @report_path ||= Rails.root.join("tmp", "explorer")

      unless @report_path.directory?
        @report_path.mkpath
      end

      @report_path
    end
  end
end
