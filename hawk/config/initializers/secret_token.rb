# Be sure to restart your server when you modify this file.

SESSION_SECRET_FILE = File.join(Rails.root, 'tmp', 'session_secret')

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
Hawk::Application.config.secret_token =
  if File.exist?(SESSION_SECRET_FILE)  # RORSCAN_ITL
    File.read(SESSION_SECRET_FILE)
  else
    # mkdir tmp here if it doesn't already exist (necessary when
    # running from a source checkout, wherein tmp does not exist,
    # which breaks script/generate...)
    d = File.join(Rails.root, 'tmp')
    Dir.mkdir d unless File.directory? d
    secret = SecureRandom.hex(64)
    File.open(SESSION_SECRET_FILE, 'w', 0600) { |f| f.write(secret) }
    secret
  end

