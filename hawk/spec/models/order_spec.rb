require "rails_helper"

describe Order do
  context 'with invalid values' do
    it 'with blank score' do
      record = Order.new
      record.score = ""
      record.valid? #run validation
      record.errors[:score].should include("Score is required")
      record.errors[:score].should_not include("Invalid score value")
    end
    it 'with invalid score' do
      record = Order.new
      record.score = "lol"
      record.valid?
      record.errors[:score].should include("Invalid score value")
      record.errors[:score].should_not include("Score is required")
    end
    it 'with blank resources' do
      record = Order.new
      record.resources = []
      record.valid?
      record.errors[:base].should include("Constraint must consist of at least two separate resources")
    end
    it 'with only one resource' do
      record = Order.new
      record.resources = [{"resources"=>["test01"], "sequential"=>"true", "action"=>"Started"}]
      record.valid?
      record.errors[:base].should include("Constraint must consist of at least two separate resources")
    end
    it 'without ID' do
      record = Order.new
      record.id = ""
      record.valid?
      record.errors[:id].should include("ID is required")
    end
  end

  context 'with valid values' do
    it 'with valid score' do
      record = Order.new
      record.score = "serialize"
      record.valid?
      record.errors[:score].should_not include("Invalid score value", "Score is required")
    end
    it 'with valid resources' do
      record = Order.new
      record.resources = [{"resources"=>["test01"], "sequential"=>"true", "action"=>"Started"},
        {"resources"=>["test02"], "sequential"=>"true", "action"=>"Started"}]
      record.valid?
      record.errors[:base].should_not include("Constraint must consist of at least two separate resources")
    end
    it 'with ID' do
      record = Order.new
      record.id = "foo"
      record.valid?
      record.errors[:id].should_not include("ID is required")
      record.errors[:score].should include("Score is required")
    end
    it 'provide everything' do
      record = Order.new
      record.id = "foo"
      record.score = "serialize"
      record.resources = [{"resources"=>["test01"], "sequential"=>"true", "action"=>"Started"},
      {"resources"=>["test02"], "sequential"=>"true", "action"=>"Started"}]
      expect(record.errors.blank?).to eq(true)
    end    
  end
end