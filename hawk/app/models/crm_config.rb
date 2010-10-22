require 'rexml/document' unless defined? REXML::Document

class CrmConfig

  # Need this to behave like an instance of ActiveRecord
  attr_reader :id
  def to_param
    (id = self.id) ? id.to_s : nil
  end

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
        content = param.elements['content']
        @all_types[name] = {
          :type     => content.attributes['type'],
          :readonly => false,
          :default  => content.attributes['default']
        }
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
    @all_props.sort! {|a,b| a.to_s <=> b.to_s }
    # These are meant to be read-only; should we hide them
    # in the editor?  grey them out? ...?
    [:"dc-version", :"expected-quorum-votes"].each do |n|
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
