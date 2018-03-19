module Api
  module V1
    class StatusController < ApplicationController
      def index
        render json: { testing_routes: "status index"}
      end
    end
  end
end
