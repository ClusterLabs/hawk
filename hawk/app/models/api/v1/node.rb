module Api
  module V1
    class Node < Api

      def initialize(root, name)
        @id = name
        @node = REXML::XPath.first(root, "/cib/configuration/nodes/node[@uname='#{name}']")
        @node = REXML::XPath.first(root, "/cib/configuration/nodes/node[@id='#{name}']") if @node.nil?
        @statenode = REXML::XPath.first(root, "/cib/status/node_state[@uname='#{name}']")
        @statenode = REXML::XPath.first(root, "/cib/status/node_state[@id='#{name}']") if @statenode.nil?
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

      def to_hash
        { id: id, state: state, type: type }
      end

    end
  end
end
