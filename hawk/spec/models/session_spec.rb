require 'rails_helper'

RSpec.describe Session, :type => :model do
  context "username and password validation" do
    it "username without providing a password" do
      record = Session.new(username: "hacluster")
      expect(record).to_not be_valid
    end
    it "username with a password" do
      record = Session.new(username: "hacluster", password: "linux")
      expect(record).to be_valid
    end
  end
end
