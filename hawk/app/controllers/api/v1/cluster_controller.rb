module Api
  module V1
    class ClusterController < ApplicationController
      def index
        render json: { testing_routes: "cluster index"}
      end
    end
  end
end
