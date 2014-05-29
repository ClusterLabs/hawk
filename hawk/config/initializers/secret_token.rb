# Be sure to restart your server when you modify this file.

SESSION_SECRET_FILE = File.join(Rails.root, 'tmp', 'session_secret')

# mkdir tmp here if it doesn't exist (which it won't, in an initial
# source checkout, which breaks `script/rails generate`)
tmpdir = File.dirname(SESSION_SECRET_FILE)
Dir.mkdir tmpdir unless File.directory? tmpdir

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
Hawk::Application.config.secret_token =
  File.open(SESSION_SECRET_FILE, File::RDWR|File::CREAT, 0600) {|f|
    # Lock this so multiple instances starting simultaneously don't
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
  }
