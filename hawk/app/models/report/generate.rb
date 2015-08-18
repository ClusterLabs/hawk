# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Report
  class Generate < Base
    attribute :from,
      String

    attribute :until,
      String

    validate do |record|
      begin
        DateTime.parse record.from
      rescue ArgumentError
        errors.add(:from, _("must be a valid datetime"))
      end

      begin
        DateTime.parse record.until
      rescue ArgumentError
        errors.add(:until, _("must be a valid datetime"))
      end
    end

    def new_record?
      false
    end

    def persisted?
      true
    end

    protected

    def persist!
      raise self.attributes.inspect
    end
  end
end
