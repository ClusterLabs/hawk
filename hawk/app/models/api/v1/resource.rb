require 'cibtools'
require 'rexml/document' unless defined? REXML::Document
require 'rexml/xpath' unless defined? REXML::XPath

module Api
  module V1
    class Resource

      def initialize(root, id)
        @id = id
        @config = REXML::XPath.first(root, "/cib/configuration//primitive[@id='#{id}']")
        lrm_resources = REXML::XPath.match(root, "/cib/status/node_state/lrm/lrm_resources/lrm_resource[@id='#{id}']")
        @instances = lrm_resources.map do |lrm_resource|
          node_state = lrm_resource.parent.parent.parent
          {
            node: node_state.attributes["uname"] || node_state.attributes["id"],
            state: CibTools.determine_resource_state(lrm_resource)
          }
        end
      end

      def id
        @id
      end

      def type
        return :clone if @config.parent.name == "clone"
        return :multistate if @config.parent.name == "master"
        :primitive
      end

      # TODO
      def state
        state = :stopped
        @instances.each do |instance|
          state = :running if state == :stopped && instance[:state] == :running
          state = :failed if instance[:state] == :failed
        end
        state
      end

      # TODO
      def maintenance
        false
      end

      def location
         @instances
      end

      def to_hash
        { id: id, type: type, state: state, maintenance: maintenance, location: location }
      end

    end
  end
end
