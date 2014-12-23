class UserCollection < Array
  def <<(record)
    if record.kind_of? Hash
      super(User.new(record))
    else
      super
    end
  end

  def build(attrs = {})
    self.push User.new(attrs)
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
    default_record = User.new.attributes

    map! do |record|
      if record.attributes == default_record
        nil
      else
        record
      end
    end.compact!
  end
end
