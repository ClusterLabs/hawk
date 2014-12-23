class Tableless
  extend ActiveModel::Naming

  include ActiveModel::Conversion
  include ActiveModel::Validations
  include FastGettext::Translation

  include Virtus.model

  attr_accessor :new_record

  def initialize(attrs = nil)
    self.attributes = attrs unless attrs.nil?
    self.new_record = true
    super
  end

  def save
    if valid?
      persist!

      true
    else
      false
    end
  end

  def persisted?
    if self.new_record
      false
    else
      true
    end
  end

  def new_record?
    if self.new_record
      true
    else
      false
    end
  end

  def update_attributes(attrs = nil)
    self.attributes = attrs unless attrs.nil?
    self.save
  end

  protected

  def create
  end

  def update
  end

  def persist!
    if new_record?
      create
    else
      update
    end
  end
end
