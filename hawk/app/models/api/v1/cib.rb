require 'cibtools'
require 'rexml/document' unless defined? REXML::Document
require 'rexml/xpath' unless defined? REXML::XPath

module Api
  module V1
    class Cib

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
        out, err, status = Util.capture3(File.basename(cmd), '-Ql')
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
    end

  end
end
