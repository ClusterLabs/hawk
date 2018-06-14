module Api
  module V1
    class Node < Cib

      def initialize(root, name)
        query_str = "uname"
        node = REXML::XPath.match(root, "/cib/configuration/nodes/node[@uname='#{name}']")
        query_str = "id" if node.nil?
        node_path = "/cib/configuration/nodes/node[@#{query_str}='#{name}']"
        node_state_path = "/cib/status/node_state[@#{query_str}='#{name}']"

        @id = name
        @node = REXML::XPath.first(root, node_path.to_s)
        @node_attributes = REXML::XPath.match(root, "#{node_path}/instance_attributes/nvpair")
        @node_utilization = REXML::XPath.match(root, "#{node_path}/utilization/nvpair")
        @statenode = REXML::XPath.first(root, node_state_path.to_s)
      end

      def id
        @id
      end

      # TODO: check if fencing is enabled and call appropriate
      # version
      def state
        CibTools.determine_online_status_fencing(@statenode)
      end

      def type
        return :remote if @node.attributes["type"] == "remote" unless @node.nil?
        return :remote if @statenode.attributes["remote_node"] == "true" unless @statenode.nil?
        :local
      end

      def attributes(attrs)
        attrs.map do |item|
          { "#{item.attributes['name']}":item.attributes['value'] }
        end
      end

      # Implicite conversion to hash
      def to_hash
        {
          id: id,
          state: state,
          type: type,
          attributes: attributes(@node_attributes),
          utilization: attributes(@node_utilization)
        }
      end

    end
  end
end
