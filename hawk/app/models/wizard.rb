# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license information.

require 'shellwords'

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
  attr_reader :output
  attr_reader :errors
  attr_reader :need_rootpw

  def persisted?
    true
  end

  def initialize(name, category, shortdesc, longdesc)
    @name = name
    my_subs = { '/' => ' ', '\\' => ' ', ':' => ' ' }
    # no special symbols are allowed in the category
    @category = category.split('').map{|i| my_subs[i] || i}.join
    @shortdesc = shortdesc
    @longdesc = longdesc
    @steps = []
    @loaded = false
    @params = nil
    @actions = nil
    @output = nil
    @errors = nil
    @need_rootpw = false
  end

  def id
    @name
  end

  def title
    @name.gsub(/[_-]/, " ")
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
      unless action.nil?
        @errors << action["error"] if action.key? "error"
        action['text'].gsub!(/\t/, "    ") if action.key? "text"
        @actions << action unless action.key? "error"
      end
    end

    @need_rootpw = @errors.empty? && @actions.any? do |action|
      return false if action['name'] == 'cib'
      if action['name'] == 'crm'
        t = (action['text'] || '').split.first || ''
        return false if ['configure', 'resource', 'cib'].any? { |c| c == t }
      end
      if action['name'] == 'call' && action['sudo'].nil? && action['nodes'] == 'local'
        return false
      end
      true
    end
  end

  def command_string
    base = ["crm", "script", "run", @name]
    @params.each do |k, v|
      if v.is_a? Hash
        v.each do |kk, vv|
          base.push "#{k}:#{kk}=#{Shellwords.escape(vv)}"
        end
      else
        base.push "#{k}=#{Shellwords.escape(v)}"
      end
    end
    base.join(" ")
  end

  def run(params, rootpw=nil)
    # TODO: live-update frontend
    @params = params
    @actions = []
    @errors = []
    @output = nil
    CrmEvents.instance.push command_string
    CrmScript.run ["run", @name, @params], rootpw do |result, err|
      @errors << err if err
      unless result.nil?
        Rails.logger.debug "result: #{result}"
        @errors << result["error"] if result.has_key? "error"
        result['text'].gsub!(/\t/, "    ") if result.has_key? "text"
        @actions << result unless result.has_key? "error"
        @output = result["output"] if result.has_key? "output"
      end
    end
    true
  end

  def update_step_values(step, params)
    params.each do |key, value|
      if Hash === value
        step.steps.select { |s| s.name == key }.each do |s|
          update_step_values(s, value)
        end
      else
        step.steps.select { |s| s.name.empty? }.each do |s|
          s.parameters.each { |p| p.value = value if p.name == key }
        end
      end
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
        raise Cib::RecordNotFound, _("Requested wizard does not exist") unless err.nil?
        w = Wizard.parse_full(item) unless item.nil?
      end
      w
    end

    def wizard_ok(item)
      workflows = {'60-nfsserver' => true,
                   'mariadb' => true,
                   'ocfs2-single' => true,
                   'webserver' => true}
      return false if item.nil? || item['name'].nil? || item['shortdesc'].nil?
      if item['category'].nil?
        item['category'] = 'basic'
      else
        return false if item['category'].strip.downcase.eql? "script"
        return false if item['category'].strip.downcase.eql?("wizard") && workflows.has_key?(item['name'])
      end
      true
    end

    def all
      Rails.cache.fetch(:all_wizards, expires_in: 2.hours) do
        [].tap do |wizards|
          CrmScript.run ["list"], nil do |item, err|
            Rails.logger.debug "Error listing scripts: #{err}" unless err.blank?
            wizards.push Wizard.parse_brief(item) if wizard_ok(item)
          end
        end
      end
    end
  end
end
