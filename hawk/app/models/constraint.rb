# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Constraint < Record
  class CommandError < StandardError
  end

  attribute :object_type, Symbol

  validate do |record|
    # to validate a new record:
    # try making the shell form and running verify;commit in a temporary shadow cib in crm
    # if it fails, report errors
    if record.errors.blank? && record.new_record && current_cib.live?
      cli = record.shell_syntax
      _out, err, rc = Invoker.instance.no_log do |i|
        i.crm_configure ['cib new', cli, 'verify', 'commit'].join("\n")
      end
      err.lines.each do |l|
        record.errors.add :base, l[7..-1] if l.start_with? "ERROR:"
      end if rc != 0
    end
  end

  def object_type
    self.class.to_s.downcase
  end

  class << self
    def all
      super(true)
    end

    def find(id, attr = 'id')
      rsc = super(id, attr)
      return rsc if rsc.is_a? Constraint
      raise Cib::RecordNotFound, _("Not a constraint")
    end

    def cib_type_fetch
      :constraints
    end

    def help_text
      super.merge(
        id: {
          type: "string",
          shortdesc: _("Constraint ID"),
          longdesc: _("Unique identifier for the constraint. May not contain spaces."),
          default: ""
        }
      )
    end
  end
end
