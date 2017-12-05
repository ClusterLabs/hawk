require "rails_helper"

unless ENV["TRAVIS"]
  describe Util do
    describe "#acl_enable?" do

      before do
        value = true
        Util.safe_x('/usr/sbin/cibadmin', '--modify', '--xml-text', %Q[<nvpair name="enable-acl" value="#{value}" id="cib-bootstrap-options-enable-acl"/>])
      end

      context "given that enable-acl property is set to true" do
        it "returns true" do
          expect(Util.acl_enabled?).to be true
        end
      end

    end
  end
end
