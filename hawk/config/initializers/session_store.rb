# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_hawk_session',
  :secret      => '219f16f183be16eefd22aeb5ba01ebb0eaf74baae18a17d5f942bb47354fd18b883a6f3218b8267e7af2562b0dfc852d3c5c1e6ba593b022dfa3ec7b89be3f5d'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
