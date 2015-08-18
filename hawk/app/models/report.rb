# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Report
  attr_accessor :id
  attr_accessor :order

  attr_accessor :archive
  attr_accessor :from
  attr_accessor :until

  def initialize(attributes)
    attributes.each do |key, value|
      self.send(
        "#{key}=".to_sym,
        value
      )
    end
  end

  def delete
    self.archive.delete
  end

  def load!



  end

  def report_path
    self.class.report_path
  end

  class << self
    def parse(file)
      hash = Digest::SHA1.hexdigest(
        file.basename(".tar.bz2").to_s
      )

      match = file.basename.to_s.match(
        /(\d{4}-\d{2}-\d{2}_\d{2}:\d{2})/
      )

      order = [
        match[0],
        match[1]
      ].join("-")

      Report.new(
        id: hash,
        order: order,

        archive: file,
        from: DateTime.parse(match[0]),
        until: DateTime.parse(match[1])
      )
    end

    def find(id)
      file = report_file(id).dup

      if file
        record = parse(file)
        record.load!

        record
      else
        nil
      end
    end

    def all
      report_files.values.map do |file|
        parse(file)
      end.sort_by(&:order)
    end

    def report_files
      files = report_path.children.select do |file|
        if file.extname == ".bz2"
          file
        end
      end

      {}.tap do |result|
        files.each do |file|
          hash = Digest::SHA1.hexdigest(
            file.basename(".tar.bz2").to_s
          )

          result[hash] = file
        end
      end
    end

    def report_file(name)
      report_files[name]
    end

    def report_path
      @report_path ||= Rails.root.join("tmp", "explorer")

      unless @report_path.directory?
        @report_path.mkpath
      end

      @report_path
    end
  end
end
