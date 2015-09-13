# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class RuleCollection < Array
  def <<(record)
    if record.kind_of? Hash
      super(Rule.new(record))
    else
      super
    end
  end

  def build(attrs = {})
    self.push Rule.new(attrs)
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
    default_record = Rule.new.attributes

    map! do |record|
      if record.attributes == default_record
        nil
      else
        record
      end
    end.compact!
  end
end
