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
end
