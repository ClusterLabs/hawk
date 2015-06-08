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
  class Runner



    # Note: outfile, errfile are based off path passed to generate() -
    # don't use them prior to a generate run, or you'll get the wrong path.
    # Lastexit is global (this is freaky/dumb - everything should be based
    # off path, and callers need to be updated to understand this - this
    # will happen when we allow multiple hb_report runs, as
    # hb_reports_controller is what cares about lastexit)
    attr_reader :path, :outfile, :errfile, :lastexit

    # Call with e.g.:
    #  ("#{Rails.root}/tmp/pids/hb_report", "/tmp/hb_report-hawk").
    # pidfile will be set based on 'tmpbase', hb_report will be generated
    # at 'path'.  If path is nil, generate won't work -- make sure you set
    # it ASAP, before calling generate or relying on outfile or errfile!
    def initialize(tmpbase, path = nil)
      @pidfile  = "#{tmpbase}.pid"
      @exitfile = "#{tmpbase}.exit"
      @timefile = "#{tmpbase}.time"
      @path     = path
      if @path
        @outfile = "#{@path}.stdout"
        @errfile = "#{@path}.stderr"
      else
        @outfile = "#{tmpbase}.stdout"
        @errfile = "#{tmpbase}.stderr"
      end
      @lastexit = File.exists?(@exitfile) ? File.new(@exitfile).read.to_i : nil
    end

    def path=(path)
      @path = path
      @outfile = "#{@path}.stdout"
      @errfile = "#{@path}.stderr"
    end

    def running?
      Util.child_active(@pidfile)
    end

    # Returns [from_time, to_time], as strings.  Note that to_time might be
    # an empty string, if no to_time was specified when calling generate.
    def lasttime
      File.exists?(@timefile) ? File.new(@timefile).read.split(",", -1) : nil
    end

    # contents of errfile as array
    def err_lines
      err = []
      begin
        File.new(@errfile).read.split(/\n/).each do |e|
          next if e.empty?
          err << e
        end if File.exists?(@errfile)
      rescue ArgumentError => e
        # This will catch 'invalid byte sequence in UTF-8' (bnc#854060)
        err << "ArgumentError: #{e.message}"
      end
      err
    end

    # contents of errfile as array, with "INFO" lines stripped (e.g. for
    # displaying warnings after an otherwise successful run)
    def err_filtered
      err_lines.select {|e|
        !e.match(/( INFO: |(cat|tail): write error)/) &&
        !e.match(/^tar:.*time stamp/)
      }
    end

    # Note: This assumes pidfile doesn't exist (will always blow away what's
    # there), so there's a possibility of a race (or lost hb_report status)
    # if two clients kick off generation at almost exactly the same time.
    # from_time and to_time (if specified) are expected to be in a sensible
    # format (e.g.: "%Y-%m-%d %H:%M")
    def generate(from_time, all_nodes=true, to_time=nil)
      [@outfile, @errfile, @exitfile, @timefile].each do |fn|
        File.unlink(fn) if File.exists?(fn)
      end
      @lastexit = nil

      f = File.new(@timefile, "w")
      f.write("#{from_time},#{to_time}")
      f.close
      pid = fork {
        args = ["-f", from_time]
        args.push("-t", to_time) if to_time
        args.push("-Z")  # Remove destination directories if they exist
        args.push("-Q")  # Requires a version of crm report which supports this
        args.push("-S") unless all_nodes
        args.push(@path)

        out, err, status = Util.run_as("root", "crm", "report", *args)
        f = File.new(@outfile, "w")
        f.write(out)
        f.close
        f = File.new(@errfile, "w")
        f.write(err)
        f.close

        # Record exit status
        f = File.new(@exitfile, "w")
        f.write(status.exitstatus)
        f.close

        # Delete pidfile
        File.unlink(@pidfile)
      }
      f = File.new(@pidfile, "w")
      f.write(pid)
      f.close
      Process.detach(pid)
    end



  end
end
