module Api
  module V1
    class StatusController < ApiController
      before_action :get_status
      attr_reader :current_user
      
      def index
        render json: @status.root.to_json
      end

      private

      def get_status
        @status = Status.new(@current_user)
      end

    end
  end
end
