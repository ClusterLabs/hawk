# Be sure to restart your server when you modify this file.

Hawk::Application.config.session_store :cookie_store, {
  :key => '_hawk_session',
  # Allow session cookie to persist for a (somewhat arbitrary) ten days.
  # This means when using the dashboard you won't be required to log in
  # to all your clusters all the time.
  :expire_after => 60 * 60 * 24 * 10
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Hawk::Application.config.session_store :active_record_store
