#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2010 Novell Inc., Tim Serong <tserong@novell.com>
#                        All Rights Reserved.
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

require 'rexml/document' unless defined? REXML::Document

class CrmConfig < CibObject

  private

  def load_meta(cmd)
    # TODO(should): make this static, don't load it every
    # time.  Do we need to re-load sometimes?  (Pacemaker
    # upgrade without restarting Hawk?)
    [ "/usr/lib64/heartbeat/#{cmd}", "/usr/lib/heartbeat/#{cmd}" ].each do |path|
      next unless File.executable?(path)
      xml = REXML::Document.new(%x[#{path} metadata 2>/dev/null])
      return unless xml.root
      xml.elements.each('//parameter') do |param|
        name = param.attributes['name'].to_sym
        @all_props << name
        content   = param.elements['content']
        # TODO(should): select by language (en)
        shortdesc = param.elements['shortdesc'].text || ''
        longdesc  = param.elements['longdesc'].text || ''
        @all_types[name] = {
          :type       => content.attributes['type'],  # boolean, enum, integer, time
          :readonly   => false,
          :shortdesc  => shortdesc,
          :longdesc   => longdesc,
          :advanced   => (shortdesc.match(/advanced use only/i)) ||
                         (longdesc.match(/advanced use only/i)) ? true : false,
          :default    => content.attributes['default']
        }
        if @all_types[name][:type] == 'enum'
          m = longdesc.match(/Allowed values:(.*)/i)
          values = m[1].split(',').map {|v| v.strip}.select {|v| !v.empty?} if m
          # Yes, this next is paranoid.  But hey, we're parsing arbitrary text here...
          @all_types[name][:values] = values unless values.empty?
        end
      end
      break
    end
    nil # Don't return anything
  end

  public

  attr_accessor :props, :all_props, :all_types

  def initialize(parent_elem, id)
    @id = id

    @props     = {}
    @all_props = []
    @all_types = {}

    load_meta 'pengine'
    load_meta 'crmd'
    load_meta 'cib'
    @all_props.sort! {|a,b| a.to_s <=> b.to_s }
    # These are meant to be read-only; should we hide them
    # in the editor?  grey them out? ...?
    [:"cluster-infrastructure", :"dc-version", :"expected-quorum-votes"].each do |n|
      @all_types[n][:readonly] = true
    end

    @elem = parent_elem.elements["cluster_property_set[@id='#{id}']"]
    # @elem will be nil here if there's no property set with that ID
    @elem.elements.each('nvpair') do |nv|
      # TODO(should): This is not smart enough to do anything
      # special with rules, scores etc.
      @props[nv.attributes['name'].to_sym] = nv.attributes['value']
    end if @elem
  end

end
