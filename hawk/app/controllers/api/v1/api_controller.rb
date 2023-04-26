module Api
  module V1
    class ApiController < ActionController::API
      HAWK_CHKPWD = "/usr/sbin/hawk_chkpwd"
      require 'yaml/store'
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :cors_preflight_check, :authenticate, except: [ :register ]
      after_action :cors_set_access_control_headers

      ApiTokenEntry = Struct.new  "ApiToken" ,:username, :api_token, :expires

      def initialize
        @current_user
      end
      
      def register
        if authenticate_user_with_pam(params[:username], params[:password])
          token_and_expiry_values = generate_and_store_token_for_user(params[:username])
          render json: token_and_expiry_values.to_json
        else
          render_unauthorized
        end
      end

      protected

        #TODO: Work on duplication of cors preflight check in application.rb
        def cors_set_access_control_headers
          headers['Access-Control-Allow-Origin'] = '*'
          headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
          headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Authorization'
          headers['Access-Control-Max-Age'] = "1728000"
        end
        
        def cors_preflight_check
          if request.method == "OPTIONS"
            headers['Access-Control-Allow-Origin'] = '*'
            headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
            headers['Access-Control-Allow-Headers'] = 'Authorization, Access-Control-Allow-Origin'
            headers['Access-Control-Max-Age'] = '1728000'
            render :text => '', :content_type => 'text/plain'
          end
        end

        def expired?(expiry_date)
          DateTime.now.to_i >= expiry_date
        end

        def authenticate
          authenticate_user_with_token || render_missing_token
        end

        def authenticate_user_with_token
          authenticate_with_http_token do |token, options|
            if File.exist? ("#{Rails.root}/api_token_entries.store")
              store = YAML.load_file("api_token_entries.store")
              store.each do | key, value |
                @current_user = value["username"]
                api_token = value["api_token"]
                expiry_date = value["expires"]
                if api_token && expiry_date && ActiveSupport::SecurityUtils.secure_compare(token, api_token) # Use secure compare to prevent timing attacks
                  if expired?(expiry_date)
                    render_expired # Prevent access when the token is expired
                  else
                    return true # Authenticated successfully
                  end
                else
                  render_invalid_token # Token invalid, or store is invalid (TODO)
                end
              end
            else
              render_registration_required # The client needs to register (no store is found)
            end
          end
        end

        def render_unauthorized
          self.headers["WWW-Authenticate"] = 'Token realm="Application"'
          render json: 'bad_credentials', status: 401
        end

        def render_invalid_token
          self.headers["WWW-Authenticate"] = 'Token realm="Application"'
          render json: 'invalid_token', status: 401
        end


        def render_missing_token
          self.headers["WWW-Authenticate"] = 'Token realm="Application"'
          render json: 'missing_token', status: 401
        end

        def render_expired
          self.headers["WWW-Authenticate"] = 'Token realm="Application"'
          render json: 'token_expired', status: 401
        end

        def render_registration_required
          self.headers["WWW-Authenticate"] = 'Token realm="Application"'
          render json: 'registration_required', status: 401
        end

        def authenticate_user_with_pam(username, password)
          # Check the username and password
          return false unless File.exist? HAWK_CHKPWD
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
          expiry_date = 1.month.from_now.to_i
          # Store the username, token and expiry date in a yaml store
          api_token_entry = ApiTokenEntry.new(username, api_token, expiry_date)
          # Check if yaml store already exists and the user already
          # own's an api token
          if File.exist? ("#{Rails.root}/api_token_entries.store")
            store = YAML.load_file("api_token_entries.store")
            if store != false && store.has_key?(username)
              return store.dig(username, :api_token)
            else
              store = YAML::Store.new "api_token_entries.store"
              store.transaction do
                #Save the data to the store.
                store[username] = api_token_entry
              end
              return api_token
            end
          else
            store = YAML::Store.new "api_token_entries.store"
	          store.transaction do
  	          #Save the data to the store.
  	          store[username] = api_token_entry
            end
	          return {api_token: api_token, expiry_date: expiry_date}
          end
        end

    end
  end
end
