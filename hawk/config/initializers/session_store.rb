# Be sure to restart your server when you modify this file.

SESSION_SECRET_FILE = File.join(RAILS_ROOT, 'tmp', 'session_secret')

# Your secret key for verifying cookie session data integrity.
# Uses contents of $RAILS_ROOT/tmp/session_secret.  Creates this
# file with suitable random contents if it doesn't already exist.
ActionController::Base.session = {
  :key         => '_hawk_session',
  :secret      => if File.exist?(SESSION_SECRET_FILE)
                    File.read(SESSION_SECRET_FILE)
                  else
                    # mkdir tmp here if it doesn't already exist (necessary when
                    # running from a source checkout, wherein tmp does not exist,
                    # which breaks script/generate...)
                    d = File.join(RAILS_ROOT, 'tmp')
                    Dir.mkdir d unless File.directory? d
                    secret = ActiveSupport::SecureRandom.hex(64)
                    File.open(SESSION_SECRET_FILE, 'w', 0600) { |f| f.write(secret) }
                    secret
                  end
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
