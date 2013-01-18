# Be sure to restart your server when you modify this file.

Hawk::Application.config.session_store :cookie_store, :key => '_hawk_session'

SESSION_SECRET_FILE = File.join(Rails.root, 'tmp', 'session_secret')

# Your secret key for verifying cookie session data integrity.
# Uses contents of $RAILS_ROOT/tmp/session_secret.  Creates this
# file with suitable random contents if it doesn't already exist.
# Note that ror-sec-scanner picks up secret assignment, but this
# is OK to ignore.
Hawk::Application.config.cookie_secret = 
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

