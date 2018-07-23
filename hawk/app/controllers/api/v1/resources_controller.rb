module Api
  module V1
    class ResourcesController < ApiController
      before_action :get_status
      attr_reader :current_user
      
      def index
        render json: @status.resources.to_json
      end

      def show
        @status.resources.each do |res_inst|
          render json: res_inst.to_json if params[:id] == res_inst.id
        end
      end

      private

      def get_status
        @status = Status.new(@current_user)
      end

    end
  end
end
