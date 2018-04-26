module Api
  module V1
    class NodesController < ApiController
      before_action :get_status

      def index
        render json: @status.nodes.to_json
      end

      # def show
      #   render json: { testing_routes: "nodes show"}
      # end

      private

      def get_status
        @status = Status.new(@current_user)
      end

    end
  end
end
