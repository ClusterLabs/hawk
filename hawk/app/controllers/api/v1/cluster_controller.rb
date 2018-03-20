module Api
  module V1
    class ClusterController < ApiController
      def index
        render json: { testing_routes: "cluster index"}
      end
    end
  end
end
