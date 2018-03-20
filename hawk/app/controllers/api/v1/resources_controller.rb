module Api
  module V1
    class ResourcesController < ApiController

      def index
        render json: { testing_routes: "resources index"}
      end

      def show
        render json: { testing_routes: "resources show"}
      end

    end
  end
end
