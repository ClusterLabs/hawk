module Api
  module V1
    class Status < Cib

      attr_accessor :state

      def initialize(user="hacluster")
        get_cib(user)
        @state = "unknown"
        @state = "offline" if mode == :offline
        @state = "online" if mode == :online
      end

      def version
        if @mode == :online
          CibTools.epoch_string @xml.root
        else
          "0:0:0"
        end
      end

      def mode
        @mode
      end

      def xml
        @xml if @mode == :online
      end

      def root
        {
          state: state,
          resources: resources,
          nodes: nodes,
        }
      end

      def state
        {
          version: version,
          state: @state
        }
      end

      def cluster
        return [] if @xml.nil?
        Cluster.new @xml
      end


      def resources
        return [] if @xml.nil?

        res_arry = []
        resource_types = ["primitive", "group", "clone", "master", "bundle"]
        resource_types.each do |res_type|
          res_arry += @xml.elements.collect("/cib/configuration//#{res_type}") do |xml|
            Resource.new @xml, xml.attributes['id'], xml.name
          end
        end
        return res_arry
      end

      def nodes
        return [] if @xml.nil?
        @xml.elements.collect("/cib/configuration/nodes/node") do |xml|
          Node.new @xml, xml.attributes['uname'] || xml.attributes['id']
        end
      end

    end
  end
end
