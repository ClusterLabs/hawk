module Api
  module V1
    class NodesController < ApiController
      before_action :get_status
      attr_reader :current_user
      
      def index
        render json: @status.nodes.to_json
      end

      def show
        @status.nodes.each do |node_inst|
          render json: node_inst.to_json if params[:id] == node_inst.id
        end
      end

      private

      def get_status
        @status = Status.new(@current_user)
      end

    end
  end
end
