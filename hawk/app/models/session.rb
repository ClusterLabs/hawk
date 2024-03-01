# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Session < Tableless
  HAWK_CHKPWD = "/usr/sbin/hawk_chkpwd"

  attribute :username, String
  attribute :password, String

  validates :username, format: { with: /[^'$]+/, message: _("Invalid username") }

  validate do |record|
    first_checks_valid = true

    unless File.exist? HAWK_CHKPWD
      record.errors[:base] << _("%s is not installed") % HAWK_CHKPWD
      first_checks_valid = false
    end

    unless File.executable? HAWK_CHKPWD
      record.errors[:base] << _("%s is not executable") % HAWK_CHKPWD
      first_checks_valid = false
    end

    if record.username.nil?
      record.errors[:base] << _("Username not specified")
      first_checks_valid = false
    end

    if record.password.nil?
      record.errors[:base] << _("Password not specified")
      first_checks_valid = false
    end

    if first_checks_valid
      IO.popen(auth_command_for(record.username), "w+") do |pipe|
        pipe.write record.password
        pipe.close_write
      end

      unless $?.exitstatus == 0
        record.errors.add(:base, :blank, message: "Invalid username or password")
      end
    end
  end

  protected

  def auth_command_for(username)
    [
      HAWK_CHKPWD,
      "passwd",
      username.shellescape
    ].join(" ")
  end
end
