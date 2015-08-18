# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Report
  class Upload < Base
    attribute :upload,
      ActionDispatch::Http::UploadedFile

    validate do |record|
      unless record.content_type == "application/x-bzip"
        errors.add(:from, _("must have correct MIME type"))
      end

      unless record.upload.original_filename =~ /\.tar\.bz2\z/
        errors.add(:from, _("must have correct file extension"))
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
      raise self.upload.inspect
    end
  end
end
