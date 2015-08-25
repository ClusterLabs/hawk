# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license information.

class Wizard
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_reader :loaded
  attr_reader :id
  attr_accessor :name
  attr_accessor :category
  attr_accessor :shortdesc
  attr_accessor :longdesc
  attr_accessor :steps
  attr_reader :params
  attr_reader :actions
  attr_reader :errors

  def persisted?
    true
  end

  def initialize(name, category, shortdesc, longdesc)
    @name = name
    @category = category
    @shortdesc = shortdesc
    @longdesc = longdesc
    @steps = []
    @loaded = false
    @params = nil
    @actions = nil
    @errors = nil
  end

  def id
    @name
  end

  def title
    @name.gsub(/[_-]/, " ").titleize
  end

  def load_from(data)
    # TODO: load steps data
    data_steps = data['steps'] || []
    data_steps.each do |step|
      steps << Step.new(self, step)
    end
    @loaded = true
  end

  def verify(params)
    @params = params
    @actions = []
    @errors = []
    CrmScript.run ["verify", @name, params], nil do |action, err|
      @errors << err if err
      @errors << action["error"] if action.has_key? "error"
      action['text'].gsub!(/\t/, "    ") if action.has_key? "text"
      @actions << action unless action.has_key? "error"
    end
  end

  def run(params)
    # TODO: Check loaded
    # TODO: live-update frontend
    # TODO: supply rootpw
    return false if @errors.nil? || @errors.length > 0
    CrmScript.run ["run", @name, @params], nil do |result, err|
      Rails.logger.debug "run: result=#{result}, err=#{err}"
    end
  end

  class << self
    def parse_brief(data)
      return Wizard.new(data['name'],
                        data['category'].strip.downcase,
                        data['shortdesc'].strip,
                        data['longdesc'])
    end

    def parse_full(data)
      wizard = Wizard.new(data['name'],
                          data['category'].strip.downcase,
                          data['shortdesc'].strip,
                          data['longdesc'])
      wizard.load_from data
      wizard
    end

    def find(name)
      w = nil
      CrmScript.run ["show", name], nil do |item, err|
        Rails.logger.error "Wizard.find: #{err}" unless err.nil?
        raise CibObject::RecordNotFound, _("Requested wizard does not exist") unless err.nil?
        w = Wizard.parse_full(item) unless item.nil?
      end
      w
    end

    def exclude_wizard(item)
      workflows = {'60-nfsserver' => true,
                   'mariadb' => true,
                   'ocfs2-single' => true,
                   'webserver' => true}
      unsupported = {'gfs2' => true,
                     'gfs2-base' => true}
      return true if item['category'].strip.downcase.eql? "script"
      return true if item['category'].strip.downcase.eql?("wizard") && workflows.has_key?(item['name'])
      return unsupported.has_key?(item['name'])
    end

    def all
      wizards = []
      CrmScript.run ["list"], nil do |item, err|
        Rails.logger.debug "Wizard.all: #{err}" unless err.nil?
        wizards << Wizard.parse_brief(item) unless item.nil? or self.exclude_wizard(item)
      end
      wizards
    end
  end
end
