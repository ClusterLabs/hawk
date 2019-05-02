# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class CrmConfig < Tableless

  attribute :crm_config, Hash, default: {}
  attribute :rsc_defaults, Hash, default: {}
  attribute :op_defaults, Hash, default: {}

  def initialize(*args)
    super
    load!
  end

  def maplist(key, include_readonly = false, include_advanced = false)
    case
    when include_readonly && include_advanced
      mapping[key]
    when !include_readonly && include_advanced
      mapping[key].reject do |key, attrs|
        attrs[:readonly]
      end
    when include_readonly && !include_advanced
      mapping[key].reject do |key, attrs|
        attrs[:advanced]
      end
    else
      mapping[key].reject do |key, attrs|
        attrs[:readonly] || attrs[:advanced]
      end
    end
  end

  def mapping
    self.class.mapping
  end

  def help_text(options)
    options.map { |key| mapping[key] }.reduce(Hash.new, :merge)
  end

  def new_record?
    false
  end

  def persisted?
    true
  end

  class << self
    def mapping
      @mapping ||= begin
        {
          rsc_defaults: Tableless::RSC_DEFAULTS,
          op_defaults: Tableless::OP_DEFAULTS,
          crm_config: {}.tap do |crm_config|
            [
              "pengine",
              "crmd",
              "cib",
              "pacemaker-schedulerd",
              "pacemaker-controld",
              "pacemaker-based"
            ].each do |cmd|
              [
                "/usr/libexec/pacemaker/#{cmd}",
                "/usr/lib64/pacemaker/#{cmd}",
                "/usr/lib/pacemaker/#{cmd}",
                "/usr/lib64/heartbeat/#{cmd}",
                "/usr/lib/heartbeat/#{cmd}"
              ].each do |path|
                next unless File.executable? path

                REXML::Document.new(%x[#{path} metadata 2>/dev/null]).tap do |xml|
                  return unless xml.root

                  xml.elements.each("//parameter") do |param|
                    name = param.attributes["name"]
                    content = param.elements["content"]
                    shortdesc = param.elements["shortdesc[@lang=\"#{I18n.locale.to_s.gsub("-", "_")}\"]|shortdesc[@lang=\"en\"]"].text || ""
                    longdesc  = param.elements["longdesc[@lang=\"#{I18n.locale.to_s.gsub("-", "_")}\"]|longdesc[@lang=\"en\"]"].text || ""

                    type = content.attributes["type"]
                    default = content.attributes["default"]

                    advanced = shortdesc.match(/advanced use only/i) || longdesc.match(/advanced use only/i)

                    crm_config[name] = {
                      type: content.attributes["type"],
                      readonly: false,
                      shortdesc: shortdesc,
                      longdesc: longdesc,
                      advanced: advanced ? true : false,
                      default: default
                    }

                    if type == "enum"
                      match = longdesc.match(/Allowed values:(.*)/i)

                      if match
                        values = match[1].split(",").map do |value|
                          value.strip
                        end.reject do |value|
                          value.empty?
                        end

                        crm_config[name][:values] = values unless values.empty?
                      end
                    end
                  end
                end

                break
              end
            end

            [
              "cluster-infrastructure",
              "dc-version",
              "expected-quorum-votes",
              "have-watchdog",
            ].each do |key|
              crm_config[key][:readonly] = true if crm_config[key]
            end
          end
        }.freeze
      end
    end
  end

  protected

  def crm_config_xpath
    @crm_config_xpath ||= "//crm_config/cluster_property_set[@id='cib-bootstrap-options']"
  end

  def crm_config_value
    @crm_config_value ||= current_cib.first crm_config_xpath
  end

  def rsc_defaults_xpath
    @rsc_defaults_xpath ||= "//rsc_defaults/meta_attributes[@id='rsc-options']"
  end

  def rsc_defaults_value
    @rsc_defaults_value ||= current_cib.first rsc_defaults_xpath
  end

  def op_defaults_xpath
    @op_defaults_xpath ||= "//op_defaults/meta_attributes[@id='op-options']"
  end

  def op_defaults_value
    @op_defaults_value ||= current_cib.first op_defaults_xpath
  end

  def current_crm_config
    {}.tap do |current|
      crm_config_value.elements.each("nvpair") do |nv|
        next if mapping[:crm_config][nv.attributes["name"]].nil?
        current[nv.attributes["name"]] = nv.attributes["value"]
      end if crm_config_value
    end
  end

  def current_rsc_defaults
    {}.tap do |current|
      rsc_defaults_value.elements.each("nvpair") do |nv|
        next if mapping[:rsc_defaults][nv.attributes["name"]].nil?
        current[nv.attributes["name"]] = nv.attributes["value"]
      end if rsc_defaults_value
    end
  end

  def current_op_defaults
    {}.tap do |current|
      op_defaults_value.elements.each("nvpair") do |nv|
        next if mapping[:op_defaults][nv.attributes["name"]].nil?
        current[nv.attributes["name"]] = nv.attributes["value"]
      end if op_defaults_value
    end
  end

  def load!
    self.crm_config = current_crm_config
    self.rsc_defaults = current_rsc_defaults
    self.op_defaults = current_op_defaults
  end

  def persist!
    writer = {
      crm_config: {},
      rsc_defaults: {},
      op_defaults: {},
    }

    crm_config.diff(current_crm_config).each do |key, change|
      next unless maplist(:crm_config).keys.include? key
      new_value, old_value = change

      if new_value.nil? || new_value.empty?
        Invoker.instance.run("crm_attribute", "--attr-name", key, "--delete-attr")
      else
        writer[:crm_config][key] = new_value
      end
    end

    rsc_defaults.diff(current_rsc_defaults).each do |key, change|
      next unless maplist(:rsc_defaults).keys.include? key
      new_value, old_value = change

      if new_value.nil? || new_value.empty?
        Invoker.instance.run("crm_attribute", "--type", "rsc_defaults", "--attr-name", key, "--delete-attr")
      else
        writer[:rsc_defaults][key] = new_value
      end
    end

    op_defaults.diff(current_op_defaults).each do |key, change|
      next unless maplist(:op_defaults).keys.include? key
      new_value, old_value = change

      if new_value.nil? || new_value.empty?
        Invoker.instance.run("crm_attribute", "--type", "op_defaults", "--attr-name", key, "--delete-attr")
      else
        writer[:op_defaults][key] = new_value
      end
    end

    cmd = [].tap do |cmd|
      writer.each do |section, values|
        next if values.empty?

        case section
        when :crm_config
          cmd.push "property $id=\"cib-bootstrap-options\""
        when :rsc_defaults
          cmd.push "rsc_defaults $id=\"rsc-options\""
        when :op_defaults
          cmd.push "op_defaults $id=\"op-options\""
        end

        values.each do |key, value|
          cmd.push [
            key,
            value.shellescape
          ].join("=")
        end
      end
    end

    if cmd.empty?
      true
    else
      out, err, rc = Invoker.instance.crm_configure_load_update(cmd.join(" "))
      rc == 0
    end
  end
end
