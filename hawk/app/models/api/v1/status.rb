require 'cibtools'
require 'rexml/document' unless defined? REXML::Document
require 'rexml/xpath' unless defined? REXML::XPath

module Api
  module V1
    class Status < Api

      attr_accessor :state
      attr_accessor :events

      def initialize(user="hacluster")
        @cib = get_cib(user)
        @events = []
        @state = "unknown"
        @state = "offline" if cib.mode == :offline
        @state = "online" if cib.mode == :online
      end


      def get_cib(user)
        @mode = :none
        @xml = nil
        cmd = "/usr/sbin/cibadmin"
        unless File.exists?(cmd)
          Rails.logger.error "Pacemaker does not appear to be installed (#{cmd} not found)"
          return
        end
        unless File.executable?(cmd)
          Rails.logger.error "Unable to execute #{cmd}"
          return
        end
        out, err, status = Util.run_as(user, File.basename(cmd), '-Ql')
        case status.exitstatus
        when 0
          @xml = REXML::Document.new(out)
          unless @xml && @xml.root
            Rails.logger.error "Failed to parse output of #{cmd} -Ql: #{out}"
            return
          end
        when 54, 13
          # 13 is cib_permission_denied (used to be 54, before pacemaker 1.1.8)
          Rails.logger.error "Permission denied for user #{user} calling #{cmd} -Ql"
          @mode = :offline
          return
        else
          Rails.logger.error "Error invoking #{cmd} -Ql: #{err}"
          @mode = :offline
          return
        end
        @mode = :online
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
          version: version,
          cluster: cluster,
          tasks: @tasks,
          nodes: nodes,
          resources: resources,
          tickets: tickets
        }
      end

      def cluster
        {
          state: @state,
          events: @events
        }
      end

      def nodes
        return [] if @xml.nil?
        @xml.elements.collect("/cib/configuration/nodes/node") do |xml|
          NodeState.new @xml, xml.attributes['uname'] || xml.attributes['id']
        end
      end

      def resources
        return [] if @xml.nil?
        @xml.elements.collect("/cib/configuration//primitive") do |xml|
          ResourceState.new @xml, xml.attributes['id']
        end
      end

    # TODO:
    # Get list of tickets and ticket status
    # from booth
    # def tickets
    #   return [] if @xml.nil?
    #   []
    # end

    def error(message)
      @events << {
        message: message,
        type: "error",
        id: []
      }
    end

    end
  end
end
