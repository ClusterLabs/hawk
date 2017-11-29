require "rails_helper"

RSpec.describe Profile, :type => :model do
  context "default language" do
    it "is I18n.locale by default" do
      profile = Profile.new
      expect(profile.language).to eq(I18n.locale.to_s.dasherize)
    end
    it "has stonith warning enabled" do
      profile = Profile.new
      expect(profile.stonithwarning).to eq(true)
    end
    it "is valid by default" do
      profile = Profile.new
      expect(profile.valid?).to eq(true)
    end
  end
end
