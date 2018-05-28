require "rails_helper"

describe Colocation do
  context 'with invalid values' do
    it 'with blank score' do
      record = Colocation.new
      record.score = ""
      record.valid? #run validation
      record.errors[:score].should include("Score is required")
    end
    it 'with invalid score' do
      record = Colocation.new
      record.score = "lol"
      record.valid?
      record.errors[:score].should include("Invalid score value")
      record.errors[:score].should_not include("Score is required")
    end
    it 'with blank resources' do
      record = Colocation.new
      record.score = "infinity"
      record.resources = []
      record.valid?
      record.errors[:base].should include("Constraint must consist of at least two separate resources")
    end
    it 'with only one resource' do
      record = Colocation.new
      record.score = "infinity"
      record.resources = [{"resources"=>["test01"], "sequential"=>"true", "action"=>"Started"}]
      record.valid?
      record.errors[:base].should include("Constraint must consist of at least two separate resources")
    end
    it 'without ID' do
      record = Colocation.new
      record.id = ""
      record.score = "infinity"
      record.valid?
      record.errors[:id].should include("ID is required")
    end
  end
  context 'with valid values' do
    it 'with valid score' do
      record = Colocation.new
      record.score = "infinity"
      record.valid?
      record.errors[:score].should_not include("Invalid score value", "Score is required")
    end
    it 'with valid resources' do
      record = Colocation.new
      record.score = "inifinity"
      record.resources = [{"resources"=>["test01"], "sequential"=>"true", "action"=>"Started"},
        {"resources"=>["test02"], "sequential"=>"true", "action"=>"Started"}]
      record.valid?
      record.errors[:base].should_not include("Constraint must consist of at least two separate resources")
    end
    it 'with ID' do
      record = Colocation.new
      record.id = "foo"
      record.score = "infinity"
      record.valid?
      record.errors[:id].should_not include("ID is required")
    end
  end
end