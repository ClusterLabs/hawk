module Api
  module V1
    class StatusController < ApiController
      def index
        render json: { testing_routes: "status index"}
      end
    end
  end
end
