module Api
  module V1
    class Resource < Cib

      def initialize(root, id)
        @id = id
        @config = REXML::XPath.first(root, "/cib/configuration//primitive[@id='#{id}']")
        lrm_resources = REXML::XPath.match(root, "/cib/status/node_state/lrm/lrm_resources/lrm_resource[@id='#{id}']")
        @instances = lrm_resources.map do |lrm_resource|
          node_state = lrm_resource.parent.parent.parent
          {
            node: node_state.attributes["uname"] || node_state.attributes["id"],
            state: CibTools.rsc_state_from_lrm_rsc_op(root, node_state.attributes["uname"] || node_state.attributes["id"], @id)
          }
        end
      end

      def id
        @id
      end

      def type
        :primitive
      end

      def script
        {
          class: @config.attributes['class'],
          provider: @config.attributes['provider'] || nil,
          type: @config.attributes['type']
        }
      end

      def attributes(root, path)
        attrs = REXML::XPath.match(root, path)
        type = File.basename(path)
        if type == "nvpair"
          attrs.map do |item|
            { "#{item.attributes['name']}": item.attributes['value'] }
          end
        else
          attrs.map do |item|
            item.attributes.each do |key, value|
              { "#{key}": value }
            end
          end
        end
      end

      # TODO
      def state
        state = :stopped
        @instances.each do |instance|
          state = :running if state == :stopped && instance[:state] == :started
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

      def belong
        type = @config.parent.name
        if ["clone", "master", "group"].include?(type)
          { id: @config.parent.attributes['id'], type: type }
        end
      end

      # Implicite conversion to hash
      def to_hash
        {
          id: id,
          type: type,
          state: state,
          script: script,
          param: attributes(@config, "instance_attributes/nvpair"),
          meta: attributes(@config, "meta_attributes/nvpair"),
          op: attributes(@config, "operations/op"),
          maintenance: maintenance,
          location: location,
          belong: belong
        }
      end

    end
  end
end
