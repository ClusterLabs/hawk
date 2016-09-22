# coding: utf-8
# Copyright (c) 2016 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license.
require 'invoker'

class Recipient < Tableless
  attribute :id, String
  attribute :value, String
  attribute :params, Hash
  attribute :meta, Hash

  validates :id,
    presence: { message: _("ID is required") },
    format: { with: /\A[a-zA-Z0-9_-]+\z/, message: _("Invalid ID") }

  validates :value, presence: { message: _("Recipient path is required") }

  def params
    @params ||= {}
  end

  def meta
    @meta ||= {}
  end
end
