module Api
  module V1
    class ResourcesController < ApiController
      before_action :get_status

      def index
        render json: @status.resources.to_json
      end

      # def show
      #   render json: { testing_routes: "resources show"}
      # end

      private

      def get_status
        @status = Status.new(@current_user)
      end

    end
  end
end
