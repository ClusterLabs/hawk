module Api
  module V1
    class ApiController < ActionController::API
      HAWK_CHKPWD = "/usr/sbin/hawk_chkpwd"
      require 'yaml/store'
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate, except: [ :register ]

      ApiTokenEntry = Struct.new :username, :api_token, :expires

      def register
        if authenticate_user_with_pam(params[:username], params[:password])
          token_value = generate_and_store_token_for_user(params[:username])
          render json: { "token": token_value}
        else
          render_unauthorized
        end
      end

      protected

        def authenticate
          authenticate_user_with_token || render_unauthorized
        end

        def authenticate_user_with_token
          authenticate_with_http_token do |token, options|
            true if token == '1'
          end
        end

        def render_unauthorized
          self.headers["WWW-Authenticate"] = 'Token realm="Application"'
          render json: 'Bad credentials', status: 401
        end

        def authenticate_user_with_pam(username, password)
          # Check the username and password
          return false unless File.exists? HAWK_CHKPWD
          return false unless File.executable? HAWK_CHKPWD
          return false if username.blank?
          return false if password.blank?
          IO.popen("#{HAWK_CHKPWD} passwd #{username.shellescape}", "w+") do |pipe|
            pipe.write password
            pipe.close_write
          end
          $?.exitstatus == 0
        end

        def generate_and_store_token_for_user(username)
          api_token = SecureRandom.hex[0,12]
          # Store the username, token and expiry date in a yaml store
	  api_token_entry = ApiTokenEntry.new(username, api_token, 1.month.from_now)
	  store = YAML::Store.new "api_token_entries.store" 
	  store.transaction do
  	    # Save the data to the store.
  	    store[:api_token_entries] = username 
            store.abort if # Toek token already existing
          end
	  return api_token
        end

    end
  end
end
