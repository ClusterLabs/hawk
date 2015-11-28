# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Tableless
  class ValidationError < RuntimeError
  end

  extend ActiveModel::Naming

  include Virtus.model

  include ActiveModel::Conversion
  include ActiveModel::Validations
  include FastGettext::Translation

  attr_accessor :new_record

  def initialize(attrs = nil)
    self.attributes = attrs unless attrs.nil?
    self.new_record = true
    super
  end

  def save
    valid? && persist!
  end

  def persisted?
    !new_record
  end

  def new_record?
    new_record
  end

  def update_attributes(attrs = nil)
    unless attrs.nil?
      ["meta", "params"].each do |key|
        attrs[key] = {} if self.respond_to?(key.to_sym) && !attrs.key?(key)
      end
      self.attributes = attrs
    end
    save
  end

  def validate!
    fail(ValidationError, errors) unless valid?
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

  class << self
    def current_cib
      Thread.current[:current_cib].call
    end
  end

  def current_cib
    self.class.current_cib
  end
end
