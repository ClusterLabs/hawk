# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class RoleCollection < Array
  def <<(record)
    if record.kind_of? Hash
      super(Role.new(record))
    else
      super
    end
  end

  def build(attrs = {})
    self.push Role.new(attrs)
  end

  def valid?
    # remove_empty!

    if map(&:valid?).include? false
      false
    else
      true
    end
  end

  protected

  def remove_empty!
    default_record = Role.new.attributes

    map! do |record|
      if record.attributes == default_record
        nil
      else
        record
      end
    end.compact!
  end
end
