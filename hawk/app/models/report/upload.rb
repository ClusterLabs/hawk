# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Report
  class Upload < Base
    attribute :upload,
      ActionDispatch::Http::UploadedFile

    validate do |record|
      unless record.upload.content_type == "application/x-bzip" ||
             record.upload.content_type == "application/x-xz" ||
             record.upload.content_type == "application/x-gz"
        errors.add(:from, _("must have correct MIME type"))
      end

      unless record.upload.original_filename =~ /\.tar\.(bz2|gz|gz)\z/
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
      path = Rails.root.join("tmp", "explorer", "uploads")
      path.mkpath unless path.directory?
      path = path.join(@upload.original_filename)
      FileUtils.rm path if path.file?
      FileUtils.cp @upload.tempfile.to_path, path
      Rails.logger.debug "Uploaded to #{path}"
      true
    end
  end
end
