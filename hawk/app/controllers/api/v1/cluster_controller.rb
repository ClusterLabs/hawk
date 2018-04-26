module Api
  module V1
    class ClusterController < ApiController
      before_action :get_status

      def index
        render json: @status.cluster.to_json
      end

      private

      def get_status
        @status = Status.new(@current_user)
      end
    end
  end
end
