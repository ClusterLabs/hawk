# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

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
