# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

require 'util'
require 'cibtools'
require 'natcmp'
require 'rexml/document' unless defined? REXML::Document
require 'rexml/xpath' unless defined? REXML::XPath

class Cib
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include FastGettext::Translation
  include Rails.application.routes.url_helpers # needed for routes

  class CibError < StandardError
    def initialize(message = nil, data = nil)
      super(message)
      @redirect_to = data.nil? ? nil : data[:redirect_to]
    end

    def head
      :bad_request
    end

    def redirect!(or_else)
      if @redirect_to.blank?
        or_else
      else
        @redirect_to
      end
    end
  end

  class RecordNotFound < CibError
    def head
      :not_found
    end
  end

  class PermissionDenied < CibError
    def head
      :forbidden
    end
  end

  class NotAuthenticated < CibError
    def head
      :forbidden
    end
  end

  attr_reader :id
  attr_reader :dc
  attr_reader :epoch
  attr_reader :nodes
  attr_reader :resources
  attr_reader :templates
  attr_reader :crm_config
  attr_reader :rsc_defaults
  attr_reader :op_defaults
  attr_reader :resource_count
  attr_reader :tickets
  attr_reader :tags
  attr_reader :alerts
  attr_reader :resources_by_id
  attr_reader :booth
  attr_reader :constraints
  attr_reader :fencing_topology

  def persisted?
    true
  end

  def meta
    @meta ||= begin
      struct = {}

      @xml.root.attributes.each do |n, v|
        struct[n.underscore.to_sym] = Util.unstring(v, '')
      end unless @xml.nil?

      struct[:epoch] = epoch
      struct[:dc] = dc

      struct[:host] = Socket.gethostname

      struct[:version] = crm_config[:dc_version]
      struct[:stack] = crm_config[:cluster_infrastructure]

      struct[:status] = cluster_status

      struct
    end
  end

  def name
    crm_config[:cluster_name] || ""
  end

  def no_quorum?
      meta[:have_quorum] == "0" && @crm_config[:no_quorum_policy] != "ignore"
  end

  def cluster_status
    case
    when errors.empty?
      maintain = nodes.map do |node|
        node[:maintenance] || false
      end

      case
      when maintain.include?(true)
        :maintenance
      else
        :ok
      end
    when !@crm_config[:stonith_enabled]
      :nostonith
    else
      :errors
    end
  end

  def live?
    id == 'live'
  end

  def cluster_name
    crm_config[:cluster_name]
  end

  def sim?
    id != 'live'
  end

  def offline?
    meta[:status] == :offline
  end

  def not_a_node?
    return false unless offline?
    !File.exist?('/var/lib/pacemaker')
  end

  def status()
    {
      meta: meta,
      errors: errors,
      booth: booth
    }.tap do |result|
      result[:crm_config] = crm_config
      result[:rsc_defaults] = rsc_defaults
      result[:op_defaults] = op_defaults
      result[:resources] = resources
      result[:resources_by_id] = resources_by_id
      result[:nodes] = nodes
      result[:tickets] = tickets
      result[:tags] = tags
      result[:alerts] = alerts
      result[:constraints] = constraints
      result[:resource_count] = resource_count
      result[:fencing_topology] = fencing_topology
    end
  end

  def primitives
    ret = []
    @resources.each do |r|
      if r.key? :children
        r[:children].each do |c|
          ret << c if c.key? :instances
        end
      elsif r.key? :instances
        ret << r
      end
    end
    ret
  end

  def find_node(node_id)
    fail(RecordNotFound, _('CIB offline: %s=%s') % ["id", node_id]) if @xml.nil?

    state = @nodes.select { |n| n[:id] == node_id || n[:uname] == node_id }
    fail(RecordNotFound, _('Node state not found: %s=%s') % ["id", node_id]) if state.blank?

    node = @xml.elements["cib/configuration/nodes/node[@uname=\"#{node_id}\"]"]
    if node
      Node.instantiate(node, state.first)
    else
      node = @xml.elements["cib/configuration/nodes/node[@id=\"#{node_id}\"]"]
      Node.instantiate(node, state.first)
    end
  end

  def nodes_ordered
    ret = []
    return ret if @xml.nil?
    @nodes.each do |state|
      xmls = @xml.elements.select { |xml| xml.attributes['id'] == state[:id] }
      xml = xmls.first if xmls
      ret << Node.instantiate(xml, state)
    end
    ret
  end

  def match(xpath)
    return [] if @xml.nil?
    REXML::XPath.match(@xml, xpath)
  end

  def first(xpath)
    return [] if @xml.nil?
    REXML::XPath.first(@xml, xpath)
  end

  protected

  def query_remote_node_container(node)
    @xml.elements.collect("cib/status/node_state/lrm/lrm_resources/lrm_resource[@id=\"#{node}\"]") { |x| x.attributes["container"] }.first
  end

  def get_resource(elem, is_managed = true, maintenance = false, clone_max = nil, is_ms = false)
    res = {
      id: elem.attributes['id'],
      object_type: elem.name,
      attributes: {},
      is_managed: is_managed && !maintenance,
      maintenance: maintenance || false,
      state: :unknown
    }
    @resources_by_id[elem.attributes['id']] = res
    elem.elements.each("meta_attributes/nvpair/") do |nv|
      res[:attributes][nv.attributes["name"]] = nv.attributes["value"]
    end
    if res[:attributes].key?("is-managed")
      res[:is_managed] = Util.unstring(res[:attributes]["is-managed"], true)
    end
    if res[:attributes].key?("maintenance")
      # A resource on maintenance is also flagged as unmanaged
      res[:maintenance] = Util.unstring(res[:attributes]["maintenance"], false)
      res[:is_managed] = false if res[:maintenance]
    end
    case elem.name
    when 'primitive'
      res[:class]     = elem.attributes['class']
      res[:provider]  = elem.attributes['provider'] # This will be nil for LSB resources
      res[:type]      = elem.attributes['type']
      res[:template]  = elem.attributes['template']
      res[:instances] = {}
      # This is a bit of a hack to ensure we have a complete set of instances later
      res[:clone_max] = clone_max if clone_max
      # Likewise to s/started/slave/
      res[:is_ms]     = is_ms
    when 'group', 'clone', 'master'
      # For non-primitives we overload :type (it's not a primitive if
      # it has children, or, for that matter, if it has no class)
      res[:type]     = elem.name
      res[:children] = []
      if elem.name == 'clone' || elem.name == 'master'
        nvpair = elem.elements["meta_attributes/nvpair[@name='clone-max']"]
        clone_max = nvpair ? nvpair.attributes['value'].to_i : @nodes.length
      end
      if elem.elements['primitive']
        elem.elements.each('primitive') do |p|
          res[:children] << get_resource(p, res[:is_managed], res[:maintenance], clone_max, is_ms || elem.name == 'master')
        end
      elsif elem.elements['group']
        res[:children] << get_resource(elem.elements['group'], res[:is_managed], res[:maintenance], clone_max, is_ms || elem.name == 'master')
      else
        # This can't happen
        Rails.logger.error "Got #{elem.name} without 'primitive' or 'group' child"
      end
    else
      # This really can't happen
      Rails.logger.error "Unknown resource type: #{elem.name}"
    end
    res
  end

  # Hack to:
  # - inject additional instances for clones if there's no LRM state for them
  # - remove default instance for clones (shouldn't be there, but will be due
  #   to orphans if you create a clone from a running primitive or group).
  # - remove clone instances from primitives (shouldn't be there, but will be
  #   due to orphans if you un-clone a running cloned primitive or group)
  # - count total number of configured resource instances
  def fix_clone_instances(rsclist)
    rsclist.each do |res|
      if res[:clone_max]
        # There'll be a stale default instance lying around if the resource was
        # started before it was cloned (bnc#711180), so ditch it.  This is all
        # getting a bit convoluted - need to rethink...
        res[:instances].delete(:default)
        instance = 0
        while res[:instances].length < res[:clone_max]
          while res[:instances].key?(instance.to_s.to_sym)
            instance += 1
          end
          res[:instances][instance.to_s.to_sym] = {
            failed_ops: [],
            is_managed: res[:is_managed] && !@crm_config[:maintenance_mode],
            maintenance: res[:maintenance] || @crm_config[:maintenance_mode] || false
          }
        end
        res[:instances].delete(:default) if res[:instances].key?(:default)
        # strip any instances outside 0..clone_max if they're not running (these
        # can be present if, e.g.: you have a clone running on all nodes, then
        # set clone-max < num_nodes, in which case there'll be stopped orphans).
        res[:instances].keys.select{|i| i.to_s.to_i >= res[:clone_max]}.each do |k|
          # safe to delete if the instance is present and its only state is stopped
          res[:instances].delete(k) if res[:instances][k].keys.length == 1 && res[:instances][k].key?(:stopped)
        end
        res.delete :clone_max
      else
        if res.key?(:instances)

          res[:instances].delete_if do |k, v|
            k != :default
          end
          # Inject a default instance if there's not one, as can be the case when
          # working with shadow CIBs.
          res[:instances][:default] = {
            failed_ops: [],
            is_managed: res[:is_managed] && !@crm_config[:maintenance_mode],
            maintenance: res[:maintenance] || @crm_config[:maintenance_mode] || false
          } unless res[:instances].key?(:default)
        end
      end
      @resource_count += res[:instances].count if res[:instances]
      fix_clone_instances(res[:children]) if res[:children]
    end
  end

  # After all the instance states have been calculated, we
  # can calculate a total resource state
  def fix_resource_states(rsclist)
    prio = {
      unknown: 0,
      stopped: 1,
      started: 2,
      slave: 3,
      master: 4,
      pending: 5,
      failed: 6
    }
    rsclist.each do |resource|
      resource[:running_on] = {}
      resource[:state] ||= :stopped
      if resource.key? :instances
        resource[:state] = :stopped if resource[:state] == :unknown
        resource[:instances].each do |_, states|
          prio.keys.each do |rstate|
            if states.key? rstate
              p1 = prio[rstate]
              p2 = prio[resource[:state]]
              resource[:state] = rstate if p1 > p2

              unless [:started, :slave, :master].find_index(rstate).nil?
                states[rstate].each do |instance|
                  resource[:running_on][instance[:node]] = rstate
                end
              end
            end
          end
        end
      end

      if resource.key? :children
        fix_resource_states(resource[:children])
        resource[:children].each do |child|
          rstate = child[:state]
          resource[:state] = rstate if (prio[rstate] || 0) > (prio[resource[:state]] || 0)
          resource[:running_on].merge! child[:running_on]
        end
      end

      # Set the state of the primitive running inside the bundle and then the bundle itself
      if resource[:object_type] == 'bundle'
        # Store the primitive in an array so rsclist.each doesn't raise an exception
        res_array = []
        res_array << resource[:primitive]
        # Set the state of the primitive inside the bundle
        fix_resource_states(res_array)
        # Set the state of the bundle
        rstate = resource[:primitive][:state]
        resource[:state] = rstate if (prio[rstate] || 0) > (prio[resource[:state]] || 0)
        resource[:running_on].merge! resource[:primitive][:running_on]
      end


      resource[:state] = :unmanaged unless resource[:is_managed]
      resource[:state] = :maintenance if resource[:maintenance] == true
    end
  end

  def inject_default_instance
    @resources_by_id.each do |k, _|
      @resources_by_id[k].delete :is_ms
      # Need to inject a default instance if we don't have any state
      # (e.g. during cluster bringup) else the panel renderer chokes.
      if @resources_by_id[k][:instances] && @resources_by_id[k][:instances].empty?
        # Always include empty failed_ops array (JS status updater relies on it)
        @resources_by_id[k][:instances][:default] = {
          failed_ops: [],
          is_managed: @resources_by_id[k][:is_managed] && !@crm_config[:maintenance_mode],
          maintenance: @resources_by_id[k][:maintenance] || @crm_config[:maintenance_mode] || false
        }
      end
    end
  end

  # After all the resource states have been calculated, we
  # can calculate a total tag state
  def fix_tag_states
    prio = {
      unknown: 0,
      unmanaged: 1,
      maintenance: 2,
      stopped: 3,
      started: 4,
      slave: 5,
      master: 6,
      pending: 7,
      failed: 8
    }
    @tags.each do |tag|
      sum_state = :unknown
      tag[:refs].each do |ref|
        tagged = @resources_by_id[ref]
        unless tagged.nil?
          rstate = tagged[:state]
          unless rstate.nil?
            if prio[rstate] > prio[sum_state]
              sum_state = rstate
            end
          end
        end
      end
      tag[:state] = sum_state
    end
  end

  def get_constraint(elem)
    objtype = {
      rsc_location: :location,
      rsc_colocation: :colocation,
      rsc_order: :order,
      rsc_ticket: :ticket
    }
    ret = {
      id: elem.attributes['id'],
      object_type: objtype[elem.name.to_sym] || elem.name,
      children: []
    }
    ["rsc", "with-rsc", "first", "then"].each do |attr|
      ret[:children] << elem.attributes[attr] unless elem.attributes[attr].nil?
    end
    ["score", "node", "resource-discovery", "ticket"].each do |attr|
      ret[attr.underscore.to_sym] = elem.attributes[attr] unless elem.attributes[attr].nil?
    end
    elem.elements.each("resource_set/resource_ref") do |ref|
      ret[:children] << ref.attributes['id']
    end
    ret
  end

  public

  def errors
    @errors ||= []
  end

  def error(msg, type = :danger, additions = {})
    additions.merge! msg: msg, type: type
    additions[type] = true

    errors.push additions
    @meta[:status] = cluster_status unless @meta.nil?
  end

  def warning(msg, additions = {})
    error(msg, :warning, additions)
  end

  def initialize(id, user, use_file = false, stonithwarning = false)
    Rails.logger.debug "Cib.initialize #{id}, #{user}, #{use_file}"

    if use_file
      cib_path = id
      # TODO(must): This is a bit rough
      cib_path.gsub!(/[^\w-]/, '')
      cib_path = "#{Rails.root}/test/cib/#{cib_path}.xml"
      raise ArgumentError, _('CIB file "%{path}" not found') % { path: cib_path } unless File.exist?(cib_path)
      @xml = REXML::Document.new(File.new(cib_path))
      #raise RuntimeError, _('Unable to parse CIB file "%{path}"') % {path: cib_path } unless @xml.root
      unless @xml.root
        error _('Unable to parse CIB file "%{path}"') % {path: cib_path }
        init_offline_cluster id, user, use_file
        return
      end
    else
      unless File.exists?('/usr/sbin/crm_mon')
        error _('Pacemaker does not appear to be installed (%{cmd} not found)') % {
          cmd: '/usr/sbin/crm_mon' }
        init_offline_cluster id, user, use_file
        return
      end
      unless File.executable?('/usr/sbin/crm_mon')
        error _('Unable to execute %{cmd}') % {cmd: '/usr/sbin/crm_mon' }
        init_offline_cluster id, user, use_file
        return
      end
      out, err, status = Util.capture3('cibadmin', '-Ql')
      case status.exitstatus
      when 0
        @xml = REXML::Document.new(out)
        unless @xml && @xml.root
          error _('Error invoking %{cmd}') % {cmd: '/usr/sbin/cibadmin -Ql' }
          init_offline_cluster id, user, use_file
          return
        end
      when 54, 13
        # 13 is cib_permission_denied (used to be 54, before pacemaker 1.1.8)
        error _('Permission denied for user %{user}') % {user: user}
        init_offline_cluster id, user, use_file
        return
      else
        error _('Error invoking %{cmd}: %{msg}') % {cmd: '/usr/sbin/cibadmin -Ql', msg: err }
        init_offline_cluster id, user, use_file
        return
      end
    end

    @id = id

    # Special-case defaults for properties we always want to see
    @crm_config = {
      cluster_infrastructure: _('Unknown'),
      dc_version: _('Unknown'),
      stonith_enabled: true,
      symmetric_cluster: true,
      no_quorum_policy: 'stop',
    }

    # Pull in everything else
    # TODO(should): This gloms together all cluster property sets; really
    # probably only want cib-bootstrap-options?
    @xml.elements.each('cib/configuration/crm_config//nvpair') do |p|
      @crm_config[p.attributes['name'].underscore.to_sym] = CibTools.get_xml_attr(p, 'value')
    end

    @rsc_defaults = {}
    @xml.elements.each('cib/configuration/rsc_defaults//nvpair') do |p|
      @rsc_defaults[p.attributes['name'].underscore.to_sym] = CibTools.get_xml_attr(p, 'value')
    end

    @op_defaults = {}
    @xml.elements.each('cib/configuration/op_defaults//nvpair') do |p|
      @op_defaults[p.attributes['name'].underscore.to_sym] = CibTools.get_xml_attr(p, 'value')
    end

    is_managed_default = true
    if @crm_config.key?(:is_managed_default) && !@crm_config[:is_managed_default]
      is_managed_default = false
    end

    @nodes = []
    @xml.elements.each('cib/configuration/nodes/node') do |n|
      uname = n.attributes['uname']
      node_id = n.attributes['id']
      state = :unclean
      standby = false
      maintenance = @crm_config[:maintenance_mode] ? true : false
      remote = n.attributes['type'] == 'remote'
      ns = @xml.elements["cib/status/node_state[@uname='#{uname}']"]
      if ns
        state = CibTools.determine_online_status(ns, crm_config[:stonith_enabled])
        selems = n.elements["instance_attributes/nvpair[@name='standby']"]
        # TODO(could): is the below actually a sane test?
        if selems && ['true', 'yes', '1', 'on'].include?(selems.attributes['value'])
          standby = true
        end
        m = n.elements["instance_attributes/nvpair[@name='maintenance']"]
        if m && ['true', 'yes', '1', 'on'].include?(m.attributes['value'])
          maintenance = true
        end
      else
        # If there's no node state at all, the node is unclean if fencing is enabled,
        # and offline if fencing is disabled.
        state = crm_config[:stonith_enabled] ? :unclean : :offline
      end
      if standby and state == :online
        state = :standby
      end

      can_fence = @crm_config[:stonith_enabled]

      # check stonith history
      if can_fence
        fence_history = Util.safe_x('/usr/sbin/stonith_admin', '-H', "#{uname}", '2>/dev/null').strip
      else
        fence_history = ""
      end

      @nodes << {
        name: uname || id,
        uname: uname,
        state: state,
        id: node_id,
        standby: standby,
        maintenance: maintenance,
        remote: remote,
        host: nil,
        fence: can_fence,
        fence_history: fence_history
      }
    end


   # add remote nodes that may not exist in cib/configuration/nodes/node
   @xml.elements.each("cib/status/node_state") do |n|
    if n.attributes['remote_node']
      uname = n.attributes['uname']
      node_id = n.attributes['id']
      # To determine the state of remote nodes, we need to look at
      # the resource by the same name
      state = :unknown
      standby = false
      maintenance = @crm_config[:maintenance_mode] ? true : false
      unless @nodes.any? { |nod| nod[:id] == node_id }
        @nodes << {
          name: uname || node_id,
          uname: uname,
          state: state,
          id: node_id,
          standby: standby,
          maintenance: maintenance,
          remote: true,
          host: nil
        }
      end
    end
  end

    # add guest nodes
    @xml.elements.each('cib/configuration//primitive/meta_attributes/nvpair[@name="remote-node"]') do |guestattr|
      uname = guestattr.attributes['value']
      n = guestattr.parent.parent
      # To determine the state of guest nodes, we need to look at
      # the resource that hosts it
      state = :unknown
      standby = false
      maintenance = @crm_config[:maintenance_mode] ? true : false
      unless @nodes.any? { |nod| nod[:uname] == uname }
        @nodes << {
          name: uname,
          uname: uname,
          state: state,
          id: uname,
          standby: standby,
          maintenance: maintenance,
          remote: false,
          host: n.attributes['id']
        }
      end
    end

    @resources = []
    @resources_by_id = {}
    @resource_count = 0
    # This gives only resources capable of being instantiated, and skips (e.g.) templates
    @xml.elements.each('cib/configuration/resources/*[self::primitive or self::group or self::clone or self::master]') do |r|
      @resources << get_resource(r, is_managed_default && !@crm_config[:maintenance_mode], @crm_config[:maintenance_mode])
    end

    # Todo: Bundle: This should be refactored to call a get_bundle method
    @xml.elements.each('cib/configuration/resources/bundle') do |b|

      # Figure out which type of container
      b.elements.each('docker' || 'rkt') do |c|
        # @container_type will be either "docker" or "rkt"
        @container_type = c.name.to_s
      end

      # Basic structure
      bundle = {
        id: b.attributes['id'],
        object_type: b.name,
        is_managed: true,
        maintenance: false,
        meta: {},
        attributes: {},
        state: :unknown,
        @container_type.to_s => {},
        network: {
          port_mapping: []
        },
        storage: {
          storage_mapping: []
        },
        primitive: {}
      }


      b.elements.each(@container_type) do |c|
        bundle[@container_type.to_s][:image] = c.attributes["image"]
        bundle[@container_type.to_s][:replicas] = c.attributes["replicas"]
        bundle[@container_type.to_s][:replicas_per_host] = c.attributes["replicas-per-host"]
        bundle[@container_type.to_s][:masters] = c.attributes["masters"]
        bundle[@container_type.to_s][:run_command] = c.attributes["run-command"]
        bundle[@container_type.to_s][:network] = c.attributes["network"]
        bundle[@container_type.to_s][:options] = c.attributes["options"]
      end
      b.elements.each("network") do |n|
        bundle[:network][:ip_range_start] = n.attributes["ip-range-start"]
        bundle[:network][:control_port] = n.attributes["control-port"]
        bundle[:network][:host_interface] = n.attributes["host-interface"]
        n.elements.each("port-mapping") do |pm|
          obj = {}
          obj[:id] = pm.attributes["id"]
          obj[:port] = pm.attributes["port"]
          obj[:internal_port] = pm.attributes["internal-port"]
          obj[:range] = pm.attributes["range"]
          bundle[:network][:port_mapping] << obj
        end
      end
      b.elements.each("storage") do |s|
        s.elements.each("storage-mapping") do |sm|
          obj = {}
          obj[:id] = sm.attributes["id"]
          obj[:source_dir] = sm.attributes["source-dir"]
          obj[:source_dir_root] = sm.attributes["source-dir-root"]
          obj[:target_dir] = sm.attributes["target-dir"]
          obj[:options] = sm.attributes["options"]
          bundle[:storage][:storage_mapping] << obj
        end
      end

      b.elements.each("primitive") do |p|
        bundle[:primitive] = get_resource(p, is_managed_default && !@crm_config[:maintenance_mode], @crm_config[:maintenance_mode])
      end

      b.elements.each("meta_attributes/nvpair/") do |nv|
        bundle[:attributes][nv.attributes["name"]] = nv.attributes["value"]
      end
      if bundle[:attributes].key?("is-managed")
        bundle[:is_managed] = Util.unstring(bundle[:attributes]["is-managed"], true)
      end
      if bundle[:attributes].key?("maintenance")
        # A resource on maintenance is also flagged as unmanaged
        bundle[:maintenance] = Util.unstring(bundle[:attributes]["maintenance"], false)
        bundle[:is_managed] = false if bundle[:maintenance]
      end

      @resources << bundle
      @resources_by_id[b.attributes['id']] = bundle

    end if Util.has_feature?(:bundle_support)

    # Templates deliberately kept separate from resources, because
    # we need an easy way of listing them separately, and they don't
    # have state we care about.
    @templates = []
    @xml.elements.each('cib/configuration/resources/template') do |t|
      @templates << {
        id: t.attributes['id'],
        class: t.attributes['class'],
        provider: t.attributes['provider'],
        type: t.attributes['type']
      }
    end if Util.has_feature?(:rsc_template)

    # TODO(must): fix me
    @constraints = []
    @xml.elements.each('cib/configuration/constraints/*') do |c|
      @constraints << get_constraint(c)
    end

    @tags = []
    @xml.elements.each('cib/configuration/tags/tag') do |t|
      @tags << {
        id: t.attributes['id'],
        state: :unknown,
        object_type: :tag,
        is_managed: true,
        maintenance: false,
        running_on: {},
        refs: t.elements.collect('obj_ref') { |ref| ref.attributes['id'] }
      }
    end

    @alerts = []
    @xml.elements.each('cib/configuration/alerts/alert') do |a|
      ret = {
        id: a.attributes['id'],
        path: a.attributes['path'],
        meta: {},
        attributes: {},
        recipients: a.elements.collect('recipient') do |rec|
          ret = {
            id: rec.attributes['id'],
            value: rec.attributes['value'],
            meta: {},
            attributes: {}
          }
          rec.elements.each('meta_attributes/nvpair/') do |nv|
            ret[:meta][nv.attributes["name"]] = nv.attributes["value"]
          end
          rec.elements.each('instance_attributes/nvpair/') do |nv|
            ret[:attributes][nv.attributes["name"]] = nv.attributes["value"]
          end
          ret
        end
      }
      a.elements.each('meta_attributes/nvpair/') do |nv|
        ret[:meta][nv.attributes["name"]] = nv.attributes["value"]
      end
      a.elements.each('instance_attributes/nvpair/') do |nv|
        ret[:attributes][nv.attributes["name"]] = nv.attributes["value"]
      end
      @alerts << ret
    end

    @fencing_topology = []
    @xml.elements.each('cib/configuration/fencing-topology/fencing-level') do |f|
      level = {
        type: nil,
        target: nil,
        value: nil,
        index: f.attributes['index'],
        devices: f.attributes['devices'].split(",")
      }
      if !f.attributes['target'].nil?
        level[:target] = f.attributes['target']
        level[:type] = "node"
      elsif !f.attributes['target-pattern'].nil?
        level[:target] = f.attributes['target-pattern']
        level[:type] = "pattern"
      elsif !f.attributes['target-attribute'].nil?
        level[:target] = f.attributes['target-attribute']
        level[:value] = f.attributes['target-value']
        level[type] = "attribute"
      end
      @fencing_topology << level
    end

    # Iterate nodes in cib order here which makes the faked up clone & ms instance
    # IDs be in the same order as pacemaker
    for node in @nodes
      @xml.elements.each("cib/status/node_state[@uname='#{node[:uname]}']/lrm/lrm_resources/lrm_resource") do |lrm_resource|
        rsc_id = lrm_resource.attributes['id']

        # logic derived somewhat from pacemaker/lib/pengine/unpack.c:unpack_rsc_op()
        state = :unknown
        substate = nil
        failed_ops = []
        ops = []
        lrm_resource.elements.each('lrm_rsc_op') do |op|
          ops << op
        end
        ops.sort { |a, b| CibTools.sort_ops(a, b) }.each do |op|
          operation = op.attributes['operation']
          id = op.attributes['id']
          call_id = op.attributes['call-id'].to_i
          rc_code = op.attributes['rc-code'].to_i
          # Cope with missing transition key (e.g.: in multi1.xml CIB from pengine/test10)
          # TODO(should): Can we handle this better?  When is it valid for the transition
          # key to not be there?
          expected = rc_code
          if op.attributes.key?('transition-key')
            k = op.attributes['transition-key'].split(':')
            expected = k[2].to_i
          end

          exit_reason = op.attributes.key?('exit-reason') ? op.attributes['exit-reason'] : ''

          # skip notifies, deletes, cancels
          next if ['notify', 'delete', 'cancel'].include? operation

          # set crm_feature_set in node information
          node[:crm_feature_set] = op.attributes['crm_feature_set'] if operation == 'monitor'

          # skip allegedly pending "last_failure" ops (hack to fix bnc#706755)
          # TODO(should): see if we can remove this in future
          next if !id.nil? && id.end_with?("_last_failure_0") && call_id == -1

          if op.attributes['call-id'].to_i == -1
            # Don't do any further processing for pending ops, but only set
            # resource state to "pending" if it's not a pending monitor
            # TODO(should): Look at doing this by "whitelist"? i.e. explicitly
            # notice pending start, stop, promote, demote, migrate_*..?
            # This would allow us to say "Staring", "Stopping", etc. in the UI.
            state = :pending if operation != "monitor"
            case operation
            when "start"
              substate = :starting
            when "stop"
              substate = :stopping
            when "promote"
              substate = :promoting
            when "demote"
              substate = :demoting
            when /^migrate/
              substate = :migrating
            end
            next
          end

          is_probe = operation == 'monitor' && op.attributes['interval'].to_i.zero?
          # Report failure if rc_code != expected, unless it's a probe,
          # in which case we only report failure when rc_code is not
          # 0 (running), 7 (not running) or 8 (running master), i.e. is
          # some error value.
          if rc_code != expected && (!is_probe || (rc_code != 0 && rc_code != 7 && rc_code != 8))

            # if on-fail == ignore for this op, pretend it succeeded for the purposes of state calculation
            ignore_failure = false
            @xml.elements.each("cib/configuration//primitive[@id='#{rsc_id.split(":")[0]}']/operations/op[@name='#{operation}']") do |e|
              next unless e.attributes["on-fail"] && e.attributes["on-fail"] == "ignore"
              # TODO(must): Verify interval is correct
              ignore_failure = true
            end

            # Want time span of failed op to link to history explorer.
            # Failed ops seem to only have last-rc-change, but in case this is
            # an incorrect assumption we'll take the earlier of last-run and
            # last-rc-change if both exist, then subtract exec-time and queue-time

            times = []
            times << op.attributes['last-rc-change'].to_i if op.attributes['last-rc-change']
            times << op.attributes['last-run'].to_i if op.attributes['last-run']
            real_start = Time.at(times.min).strftime("%Y-%m-%d %H:%M")
            fail_start = fail_end = times.min
            if (fail_start)
              fail_start -= (op.attributes['exec-time'].to_i / 1000) if op.attributes['exec-time']
              fail_start -= (op.attributes['queue-time'].to_i / 1000) if op.attributes['queue-time']

              # Now extend by (a somewhat arbitrary) ten minutes on either side
              fail_start -= 600
              fail_end += 600

              fail_start = Time.at(fail_start).strftime("%Y-%m-%d %H:%M")
              fail_end = Time.at(fail_end).strftime("%Y-%m-%d %H:%M")
            end

            failed_op = {
              node: node[:uname],
              call_id: op.attributes['call-id'],
              op: operation,
              rc_code: rc_code,
              exit_reason: exit_reason,
              fail_start: fail_start,
              fail_end: fail_end
            }
            linky = fail_start ? Rails.application.routes.url_helpers.reports_path(from_time: fail_start, to_time: fail_end) : ""
            failed_ops << failed_op
            error(_('%{fail_start}: Operation %{op} failed for resource %{resource} on node %{node}: call-id=%{call_id}, rc-code=%{rc_mapping} (%{rc_code}), exit-reason=%{exit_reason}') % {
                    node: node[:uname],
                    resource: "<strong>#{rsc_id}</strong>".html_safe,
                    call_id: op.attributes['call-id'],
                    op: "<strong>#{operation}</strong>".html_safe,
                    rc_mapping: CibTools.rc_desc(rc_code),
                    rc_code: rc_code,
                    exit_reason: exit_reason.blank? ? 'none' : exit_reason,
                    fail_start: real_start || '0000-00-00 00:00'
                  },
                  :danger,
                  link: linky
                )

            if ignore_failure
              failed_ops[-1][:ignored] = true
              rc_code = expected
            elsif operation == "stop"
              # We have a failed stop, the resource is failed (bnc#879034)
              state = :failed
              # Also, the node is thus unclean if STONITH is enabled.
              node[:state] = :unclean if @crm_config[:stonith_enabled]
            end
          end

          state = CibTools.op_rc_to_state operation, rc_code, state

          # check for guest nodes
          if !op.attributes['on_node'].nil? && [:master, :started].include?(state) && lrm_resource.attributes['container'].nil? 
            @nodes.select { |n| n[:uname] == rsc_id }.each do |guest|
              guest[:host] = node[:uname]
              guest[:remote] = true
            end
          end
        end


        # TODO(should): want some sort of assert "status != :unknown" here
        # Now we've got the status on this node, let's stash it away
        (rsc_id, instance) = rsc_id.split(':')
        # Need check for :instances in case an orphaned resource has same id
        # as a currently extant clone parent (bnc#834198)
        if @resources_by_id[rsc_id] && @resources_by_id[rsc_id][:instances]
          update_resource_state @resources_by_id[rsc_id], node, instance, state, substate, failed_ops
          # NOTE: Do *not* add any more keys here without adjusting the renamer above
          # else
          # It's an orphan - guest nodes / bundles create a bunch of these
          # Rails.logger.debug "Ignoring orphaned resource #{rsc_id + (instance ? ':' + instance : '')}"
        end
      end
    end

    fix_clone_instances @resources
    inject_default_instance
    fix_resource_states @resources
    fix_tag_states

    # Now we can patch up the state of remote and guest nodes
    @nodes.each do |n|
      next if n[:state] == :unclean
      next unless n[:remote] || n[:host]
      rsc = @resources_by_id[n[:id]]
      if rsc
        rsc_state = rsc[:state]
      elsif n[:host]
        rsc_state = CibTools.rsc_state_from_lrm_rsc_op(@xml, n[:host], n[:id])
      end
      # node has a matching resource:
      # get state from resource.rb
      if [:master, :slave, :started].include?(rsc_state)
        n[:state] = :online
      elsif rsc && [:failed].include?(rsc_state)
        n[:state] = :unclean
      elsif rsc_state != :pending
        n[:state] = :offline
      end
    end

    # Now we can sort the node array
    @nodes.sort!{|a,b| a[:uname].natcmp(b[:uname], true)}

    feature_sets = {}
    @nodes.each do |n|
      if n.key? :crm_feature_set
        fs = n[:crm_feature_set]
        feature_sets[fs] ||= []
        feature_sets[fs] << n[:name]
      end
    end
    if feature_sets.count > 1
      details = feature_sets.map { |k, v| "%s = %s" % [v.join(", "), k] }.join("; ")
      warning _('Partial upgrade detected! Nodes report different CRM versions: %s') % details
    end

    # TODO(should): Can we just use cib attribute dc-uuid?  Or is that not viable
    # during cluster bringup, given we're using cibadmin -l?
    # Note that crmadmin will wait a long time if the cluster isn't up yet - cap it at 100ms
    @dc = Util.safe_x('/usr/sbin/crmadmin', '-t', '100', '-D', '2>/dev/null').strip
    s = @dc.rindex(' ')
    @dc.slice!(0, s + 1) if s
    @dc = _('Unknown') if @dc.empty?

    @epoch = CibTools.epoch_string @xml.root

    # Tickets will always have a granted property (boolean).  They may also
    # have a last-granted timestamp too, but this will only be present if a
    # ticket has ever been granted - it won't be there for tickets we only
    # pick up from rsc_ticket constraints.
    @tickets = {}
    @xml.elements.each("cib/status/tickets/ticket_state") do |ts|
      t = ts.attributes["id"]
      ticket = {
        id: t,
        state: :revoked,
        granted: Util.unstring(ts.attributes["granted"], false),
        standby: Util.unstring(ts.attributes["standby"], false),
        last_granted: ts.attributes["last-granted"]
      }
      ticket[:state] = :granted if ticket[:granted]
      ticket[:state] = :standby if ticket[:standby]
      @tickets[t] = ticket
    end

    # Pick up tickets defined in rsc_ticket constraints
    @xml.elements.each("cib/configuration/constraints/rsc_ticket") do |rt|
      t = rt.attributes["ticket"]
      if @tickets[t]
        @tickets[t][:constraints] ||= []
        @tickets[t][:constraints].push rt.attributes["id"]
      else
        @tickets[t] = {
          id: t,
          state: :revoked,
          granted: false,
          standby: false,
          last_granted: nil,
          constraints: [rt.attributes["id"]]
        }
      end
    end

    @booth = {sites: [], arbitrators: [], tickets: [], me: nil}
    # Figure out if we're in a geo cluster
    File.readlines("/etc/booth/booth.conf").each do |line|
      m = line.match(/^\s*(site|arbitrator|ticket)\s*=(.+)/)
      next unless m
      v = Util.strip_quotes(m[2].strip)
      next unless v
      # This split is to tear off ticket expiry times if present
      # (although they should no longer be set like this since the
      # config format changed, but still doesn't hurt)
      @booth["#{m[1]}s".to_sym] << v.split(";")[0]
    end if File.exists?("/etc/booth/booth.conf")

    # Figure out if we're a site in a geo cluster (based on existence of
    # IPaddr2 resource with same IP as a site in booth.conf)
    if !@booth[:sites].empty?
      @booth[:sites].sort!
      booth_resource_id = nil
      @xml.elements.each("cib/configuration//primitive[@type='IPaddr2']/instance_attributes/nvpair[@name='ip']") do |elem|
        ip = CibTools.get_xml_attr(elem, "value")
        next unless @booth[:sites].include?(ip)

        # Get actual value of resource after applying
        # any rule expressions
        resource_node = REXML::XPath.first(elem, "ancestor::primitive")
        if booth_resource_id != resource_node.attributes["id"]
          booth_resource_id = resource_node.attributes["id"]
          ip = Util.safe_x('crm_resource', '-r', "#{booth_resource_id}", '-g', 'ip').strip
          next unless @booth[:sites].include?(ip)

          if !@booth[:me]
            @booth[:me] = ip
          elsif @booth[:me] != ip
            Rails.logger.warn "Multiple booth sites in CIB (first match was #{@booth[:me]}, also found #{ip})"
          end
        end
      end
    end

    if @booth[:me]
      # Pick up tickets defined in booth config
      @booth[:tickets].each do |t|
        @tickets[t] = {
          id: t,
          state: :revoked,
          granted: false,
          standby: false,
          last_granted: nil
        } unless @tickets[t]
      end

      # try to get a bit more ticket info
      Util.safe_x('/usr/sbin/booth', 'client', 'list', '2>/dev/null').split("\n").each do |line|
        t = nil
        line.split(",").each do |pair|
          m = pair.match(/(ticket):\s*(.*)/)
          t = m[2] if m
        end
        line.split(",").each do |pair|
          m = pair.match(/(leader|expires|commit):\s*(.*)/)
          @tickets[t][m[1].to_sym] = m[2] if m
        end if t && @tickets[t]
      end
    end

    # set ticket state correctly
    @tickets.each do |_, ticket|
      if ticket[:state] == :revoked && (ticket[:leader] && ticket[:leader].downcase != "none")
        ticket[:state] = :elsewhere
      end
    end

    error _("Partition without quorum! Fencing and resource management is disabled.") if no_quorum?

    check_drbd_status

    @nodes.each do |n|
      if n[:state] == :unclean
        error _('Node "%{node}" is UNCLEAN and needs to be fenced.') % { node: "<strong>#{n[:uname]}</strong>".html_safe }
      end
    end

    warning(
      _("STONITH is disabled. For normal cluster operation, STONITH is required."),
      link: edit_cib_crm_config_path(cib_id: @id)
    ) unless @crm_config[:stonith_enabled] || !stonithwarning
  end

  def init_offline_cluster(id, user, use_file)
    @id = id

    @meta = {
      epoch: "",
      dc: "",
      host: "",
      version: "",
      stack: "",
      status: :offline
    }

    @crm_config = {
      cluster_infrastructure: _('Unknown'),
      dc_version: _('Unknown')
    }
    @nodes = []
    @resources = []
    @resources_by_id = {}
    @resource_count = 0
    @templates = []
    @constraints = []
    @tags = []
    @tickets = []
    @fencing_topology = []
  end

  def update_resource_state(resource, node, instance, state, substate, failed_ops)
    # m/s slave state hack (*sigh*)
    state = :slave if resource[:is_ms] && state == :started
    instances = resource[:instances]

    if !instance && resource.key?(:clone_max)
      # Pacemaker commit 427c7fe6ea94a566aaa714daf8d214290632f837 removed
      # instance numbers from anonymous clones.  Too much of hawk wants
      # these, so we fake them back in if they're not present, by getting
      # the current maximum instance number (if present) and incrementing
      # it.
      # Note: instance at this point is a string because that's what
      # everything else expects
      instance = instances.select {|k,v| Util.numeric?(k.to_s)}.map {|k,v| k.to_s.to_i}.max
      if instance.nil?
        instance = "0"
      else
        instance = (instance + 1).to_s
      end
    end

    if instance && state != :stopped && state != :unknown
      # For clones, it's possible we need to rename an instance if
      # there's already a running instance with this ID.  An instance
      # is running (or possibly failed, as after a failed stop) iff:
      # - @resources_by_id[id][:instances][instance] exists, and,
      # - there are state keys other than :stopped, :unknown, :is_managed or :failed_ops present
      alt_i = instance
      while instances[alt_i] &&
            instances[alt_i].count{|k,v| (k != :stopped && k != :unknown && k != :is_managed && k != :failed_ops && k != :maintenance)} > 0
        alt_i = (alt_i.to_i + 1).to_s
      end
      if alt_i != instance
        rsc_id = resource[:id]
        Rails.logger.debug "Internally renamed #{rsc_id}:#{instance} to #{rsc_id}:#{alt_i} on #{node[:uname]}"
        instance = alt_i
      end
      instance = instance.to_sym
    else
      # instance will be nil here for regular primitives
      instance = :default
    end

    # Carry is_managed into the instance itself (needed so we can correctly
    # display unmanaged clone instances if a single node is on maintenance,
    # but only do this on first initialization else state may get screwed
    # up later
    instances[instance] = {
      is_managed: resource[:is_managed] && !@crm_config[:maintenance_mode],
      maintenance: resource[:maintenance] || @crm_config[:maintenance_mode] || false
    } unless instances[instance]
    instances[instance][state] ||= []
    n = { node: node[:uname] }
    n[:substate] = substate if substate
    instances[instance][state] << n
    instances[instance][:failed_ops] = [] unless instances[instance][:failed_ops]
    instances[instance][:failed_ops].concat failed_ops
    if state != :unknown && state != :stopped && node[:maintenance]
      # mark it unmanaged if the node is on maintenance and it's actually
      # running here (don't mark it unmanaged if it's stopped on this
      # node - it might be running on another node)
      instances[instance][:is_managed] = false
      instances[instance][:maintenance] = true
    end

    resource
  end

  def check_drbd_status
    # if there are any running drbd resources on this node and a drbdadm command,
    # check drbdadm status
    # do we need sudo to do it?
    me = Socket.gethostname
    has_drbd = false

    return unless File.executable? "/sbin/drbdadm"

    warn_diskstates = ["Failed", "Inconsistent", "Outdated", "DUnknown"].to_set
    warn_connectionstates = ["StandAlone", "Connecting", "Timeout", "BrokenPipe", "NetworkFailure", "ProtocolError"].to_set

    @resources_by_id.each do |_name, r|
      t = r[:type] == "drbd"
      active = [:master, :slave, :running].include? r[:running_on][me]
      has_drbd ||= t && active
    end
    if has_drbd
      status = Util.safe_x("/sbin/drbdadm", "status")
      curr = nil
      curr_peer = nil
      status.each_line do |l|
        if m = /^(\w+)\s*role:(\w+)$/.match(l)
          curr = m[1]
          curr_peer = nil
        elsif curr
          if m = /^  disk:(\w+)/.match(l)
            warning(_("DRBD disk %{d} is %{s} on %{n}") % { d: curr, s: m[1], n: me}) if warn_diskstates.include? m[1]
          elsif m = /^  (\w+)\s*role:(\w+)$/.match(l)
            curr_peer = m[1]
          elsif m = /^    peer-disk:(\w+)$/.match(l)
            warning(_("DRBD disk %{d} is %{s} on %{n}") % { d: curr, s: m[1], n: curr_peer}) if warn_diskstates.include? m[1]
          elsif m = /^  (\w+) connection:(\w+)$/.match(l)
            warning(_("DRBD connection for %{d} to %{n} is %{s}") % { d: curr, s: m[2], n: m[1]}) if warn_connectionstates.include? m[2]
          end
        end
      end
    end
  end
end
