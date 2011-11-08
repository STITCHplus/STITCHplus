# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_Sparql_session',
  :secret      => '7b96505fc72411964338f83e43d70047b8e9059db474b556df3f4c41ab5a891fc34cf1562fd5560ec150bf677fc2b540d6eb53e701f5516419b6ce32e03a8ea0'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
