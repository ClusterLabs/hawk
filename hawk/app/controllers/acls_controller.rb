#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2011-2014 SUSE LLC, All Rights Reserved.
#
# Author: Tim Serong <tserong@suse.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it would be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Further, this software is distributed without any warranty that it is
# free of the rightful claim of any third person regarding infringement
# or the like.  Any license provided herein, whether implied or
# otherwise, applies only to this software file.  Patent licenses, if
# any, provided herein do not apply to combinations of this program with
# other software, or any other product whatsoever.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston MA 02111-1307, USA.
#
#======================================================================

=begin

- list roles
  - roles have one or more rules
- list users
  - users can either be assigned one or more roles, or have one or more rules

- roles are ordered
- rules are ordered (need to be moveable, ideally draggable?)

- users can be assigned roles on the main screen?

- rule list
  - [right v] [xpath|tag|ref|tag ref] [attribute]

- have rules as either predefined (monitor, operator, full control) or
  advanced which shows full rule editor.

- forcibly create default roles?  (no, probably not...)

* ugh, quoting

        <write xpath="//crm_config//nvpair[@name=&apos;maintenance-mode&apos;]" id="operator-write"/>

* would be kind of nice to be able to do everything via the shell rather than
  with XML...  see how we go.

=end

class AclsController < ApplicationController
  before_filter :login_required

  layout 'main'
#  before_filter :get_cib
#  def get_cib
#    @cib = Cib.new params[:cib_id], current_user
#  end

  def initialize
    super
    @title = _('Access Control Lists')
  end

  # TODO(must): Can this get permission denied?  Say a user that can't see ACLs...?
  def index
    @roles = Role.all
    @users = User.all
    # So that's at least three cibadmin calls for each pageload here...
    @enable_acl = !Util.safe_x('/usr/sbin/cibadmin', '-Ql', '--xpath',
      "//configuration//crm_config//nvpair[@name='enable-acl' and @value='true']").chomp.empty?
    cib = Util.safe_x('/usr/sbin/cibadmin', '-Ql', '--xpath', "/cib[@validate-with]").lines.first
    if m = cib.match(/validate-with=\"pacemaker-([0-9.]+)\"/)
      @supported_schema = m.captures[0].to_f >= 2.0
    else
      @supported_schema = false
    end
  end
end
