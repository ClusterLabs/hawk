#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2015 SUSE LLC, All Rights Reserved.
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

Rails.root.join("tmp", "session_secret").tap do |secret_file|
  secret_file.dirname.mkpath unless secret_file.dirname.directory?

  # Your secret key for verifying the integrity of signed cookies.
  # If you change this key, all old signed cookies will become invalid!
  # Make sure the secret is at least 30 characters and all random,
  # no regular words or you"ll be exposed to dictionary attacks.
  Rails.application.secrets.secret_key_base = secret_file.open(
    File::RDWR | File::CREAT,
    0600
  ) do |f|
    # Lock this so multiple instances starting simultaneously don"t
    # race and write different secrets, which would otherwise lead to
    # unexpectedly being randomly logged out of hawk (at least until
    # the next time hawk is restarted, after which the problem would
    # magically evaporate).
    f.flock(File::LOCK_EX)

    secret = f.read
    if secret.empty?
      secret = SecureRandom.hex(64)

      f.rewind
      f.write(secret)
    end

    secret
  end
end
