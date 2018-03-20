module Api
  module V1
    class ApiController < ActionController::API

      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate

      protected

        def authenticate
          authenticate_token || render_unauthorized
        end

        def authenticate_token
          authenticate_with_http_token do |token, options|
            true
          end
        end

        def render_unauthorized
          self.headers["WWW-Authenticate"] = 'Token realm="Application"'
          render json: 'Bad credentials', status: 401
        end

    end
  end
end
