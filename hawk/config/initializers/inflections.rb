# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

ActiveSupport::Inflector.inflections do |inflect|
  inflect.uncountable "crm_config"

  inflect.acronym "DC"
  inflect.acronym "SAP"
  inflect.acronym "NFS"
  inflect.acronym "STONITH"
  inflect.acronym "IP"
  inflect.acronym "ID"
  inflect.acronym "LVS"
  inflect.acronym "OCFS2"
  inflect.acronym "cLVM"
  inflect.acronym "CIDR"
  inflect.acronym "SBD"
  inflect.acronym "QA"
end

module ActiveSupport::Inflector
  # does the opposite of humanize ... mostly.
  # Basically does a space-substituting .underscore
  def dehumanize(the_string)
    result = the_string.to_s.dup
    result.downcase.gsub(/ +/,'_')
  end
end

class String
  def dehumanize
    ActiveSupport::Inflector.dehumanize(self)
  end
end
