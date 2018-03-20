module Api
  module V1
    class NodesController < ActionController::API

      def index
        render json: { testing_routes: "nodes index"}
      end

      def show
        render json: { testing_routes: "nodes show"}
      end

    end
  end
end
