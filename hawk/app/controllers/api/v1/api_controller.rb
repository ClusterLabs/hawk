module Api
  module V1
    class ApiController < ActionController::API
      HAWK_CHKPWD = "/usr/sbin/hawk_chkpwd"
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate, except: [ :register ]

      def register
        if authenticate_user(params[:username], params[:password])
          render json: { "token": '1'}
        else
          render_unauthorized
        end
      end

      protected

        def authenticate
          authenticate_token || render_unauthorized
        end

        def authenticate_token
          authenticate_with_http_token do |token, options|
            true if token == '1'
          end
        end

        def render_unauthorized
          self.headers["WWW-Authenticate"] = 'Token realm="Application"'
          render json: 'Bad credentials', status: 401
        end

        def authenticate_user(username, password)
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

    end
  end
end
