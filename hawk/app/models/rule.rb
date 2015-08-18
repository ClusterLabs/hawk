# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Rule < Tableless
  attr_accessor :id

  attribute :right, String, default: 'read'
  attribute :xpath, String, default: ''
  attribute :tag, String, default: ''
  attribute :ref, String, default: ''
  attribute :attribute, String, default: ''

  validates :right, presence: true
  validates :xpath, presence: true

  def save
    valid?
  end

  def new_record?
    true
  end
end
