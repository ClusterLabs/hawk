require 'util'
require 'natcmp'

module Api
  module V1
    class Cluster < Cib


      def initialize(xml)
        @cluster = {
          cluster_infrastructure: _('Unknown'),
          dc_version: _('Unknown'),
          stonith_enabled: true,
          symmetric_cluster: true,
          no_quorum_policy: 'stop',
          epoch: _('Unknown'),
          dc: _('Unknown'),
          host: _('Unknown')
                }

          xml.elements.each('cib/configuration/crm_config//nvpair') do |p|
            @cluster[p.attributes['name'].underscore.to_sym] = CibTools.get_xml_attr(p, 'value')
          end

          @cluster[:epoch] = CibTools.epoch_string xml.root
          @dc = Util.safe_x('/usr/sbin/crmadmin', '-t', '100', '-D', '2>/dev/null').strip
          s = @dc.rindex(' ')
          @dc.slice!(0, s + 1) if s
          @dc = _('Unknown') if @dc.empty?
          @cluster[:dc] = @dc

          @cluster[:host] = Socket.gethostname
      end

      def cluster
        @cluster
      end

       # Implicite conversion to hash
      def to_hash
        cluster
      end

    end
  end
end

