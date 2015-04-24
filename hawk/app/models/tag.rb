class Tag < CibObject
  include FastGettext::Translation

  @attributes = :refs
  attr_accessor *@attributes

  def initialize(attributes = nil)
    @refs = []
    super
  end

  def validate
    error _('Empty tag') if @refs.empty?
  end

  def create
    if CibObject.exists?(id)
      error _('The ID "%{id}" is already in use') % { :id => @id }
      return false
    end

    cmd = "tag #{@id}:"
    @refs.each do |r|
      cmd += " #{r}"
    end

    result = Invoker.instance.crm_configure cmd
    unless result == true
      error _('Unable to create tag: %{msg}') ^ { :msg => result }
      return false
    end

    true
  end

  def update
    # Saving an existing tag
    unless CibObject.exists?(id, 'tag')
      error _('Tag ID "%{id}" does not exist') % { :id => @id }
      return false
    end

    begin
      # TODO
      # FIXME
      #merge_nvpairs(@xml, 'meta_attributes', @meta)

      Invoker.instance.cibadmin_replace @xml.to_s
    rescue NotFoundError, SecurityError, RuntimeError => e
      error e.message
      return false
    end

    true
  end

  class << self
    def instantiate(xml)
      res = allocate
      res.instance_variable_set(:@refs, xml.elements.collect('obj_ref') {|e| e.attributes['id'] })
      res
    end
    def all
      super "tag"
    end
  end
end
