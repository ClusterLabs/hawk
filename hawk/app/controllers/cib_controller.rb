require 'rexml/document' unless defined? REXML::Document

class CibController < ApplicationController
  # TODO: uncomment this for security!
  #before_filter :login_required

  protected

  # Gives back a string, boolean if value is "true" or "false",
  # or nil if attribute doesn't exist and there's no default
  # (roughly equivalent to crm_element_value() in Pacemaker)
  # TODO(should): be nice to get integers auto-converted too
  def get_xml_attr(elem, name, default = nil)
    v = elem.attributes[name] || default
    ['true', 'false'].include?(v.class == String ? v.downcase : v) ? v.downcase == 'true' : v
  end

  def get_property(property, default = nil)
    # TODO(could): theoretically this xpath is a bit loose.
    e = @cib.elements["//nvpair[@name='#{property}']"]
    e ? get_xml_attr(e, 'value', default) : default
  end

  def get_resource(elem)
    res = {
      :id => elem.attributes['id']
    }
    case elem.name
    when 'primitive'
      res[:class]    = elem.attributes['class']
      res[:provider] = elem.attributes['provider'] # This will be nil for LSB resources
      res[:type]     = elem.attributes['type']
    when 'group', 'clone', 'master'
      # For non-primitives we overload :type (it's not a primitive if
      # it has children, or, for that matter, if it has no class)
      res[:type]     = elem.name
      res[:children] = []
      if elem.elements['primitive']
        elem.elements.each('primitive') do |p|
          res[:children] << get_resource(p)
        end
      elsif elem.elements['group']
        res[:children] << get_resource(elem.elements['group'])
      else
        # This can't happen
      end
    else
      # This can't happen
      # TODO(could): whine
    end
    res
  end

  # transliteration of pacemaker/lib/pengine/unpack.c:determine_online_status_fencing()
  # ns is node_state element from CIB
  def determine_online_status_fencing(ns)
    ha_state    = get_xml_attr(ns, 'ha', 'dead')
    in_ccm      = get_xml_attr(ns, 'in_ccm')
    crm_state   = get_xml_attr(ns, 'crmd')
    join_state  = get_xml_attr(ns, 'join')
    exp_state   = get_xml_attr(ns, 'expected')

    # expect it to be up (more or less) if 'shutdown' is '0' or unspecified
    expected_up = get_xml_attr(ns, 'shutdown', '0') == 0

    state = :unclean
    if in_ccm && ha_state == 'active' && crm_state == 'online'
      case join_state
      when 'member'         # rock 'n' roll (online)
        state = :online
      when exp_state        # coming up (!online)
        state = :offline
      when 'pending'        # technically online, but not ready to run resources
        state = :pending    # (online + pending + standby)
      when 'banned'         # not allowed to be part of the cluster
        state = :standby    # (online + pending + standby)
      else                  # unexpectedly down (unclean)
        state = :unclean
      end
    elsif !in_ccm && ha_state =='dead' && crm_state == 'offline' && !expected_up
      state = :offline      # not online, but cleanly
    elsif expected_up
      state = :unclean      # expected to be up, mark it unclean
    else
      state = :offline      # offline
    end
    return state
  end

  # transliteration of pacemaker/lib/pengine/unpack.c:determine_online_status_no_fencing()
  # ns is node_state element from CIB
  # TODO(could): can we consolidate this with determine_online_status_fencing?
  def determine_online_status_no_fencing(ns)
    ha_state    = get_xml_attr(ns, 'ha', 'dead')
    in_ccm      = get_xml_attr(ns, 'in_ccm')
    crm_state   = get_xml_attr(ns, 'crmd')
    join_state  = get_xml_attr(ns, 'join')
    exp_state   = get_xml_attr(ns, 'expected')

    # expect it to be up (more or less) if 'shutdown' is '0' or unspecified
    expected_up = get_xml_attr(ns, 'shutdown', '0') == 0

    state = :unclean
    if !in_ccm || ha_state == 'dead'
      state = :offline
    elsif crm_state == 'online'
      if join_state == 'member'
        state = :online
      else
        # not ready yet (should this break down to pending/banned like
        # determine_online_status_fencing?  It doesn't in unpack.c...)
        state = :offline
      end
    elsif !expected_up
      state = :offline
    else
      state = :unclean
    end
    return state
  end

  public

  def index
    render :json => [ 'live' ]
  end

  def create
    head :forbidden
  end

  def new
    head :forbidden
  end

  def edit
    head :forbidden
  end

  def show
    # Only provide the live CIB (no shadow functionality yet)
    unless params[:id] == 'live'
      head :not_found
      return
    end

    @cib = REXML::Document.new(%x[/usr/sbin/cibadmin -Ql 2>/dev/null])
    # If this failed, there'll be no root element
    unless @cib.root
      render :json => nil
      return
    end

    # Special-case properties we always want to see
    crm_config = {
      :cluster_infrastructure       => get_property('cluster-infrastructure') || _('Unknown'),
      :dc_version                   => get_property('dc-version') || _('Unknown'),
      :default_resource_stickiness  => get_property('default-resource-stickiness', 0), # TODO(could): is this documented?
      :stonith_enabled              => get_property('stonith-enabled', true),
      :symmetric_cluster            => get_property('symmetric-cluster', true),
      :no_quorum_policy             => get_property('no-quorum-policy', 'stop'),
    }

    # Pull in everything else
    # TODO(should): This gloms together all cluster property sets; really
    # probably only want cib-bootstrap-options?
    @cib.elements.each('cib/configuration/crm_config//nvpair') do |p|
      sym = p.attributes['name'].tr('-', '_').to_sym
      next if crm_config[sym]
      crm_config[sym] = get_xml_attr(p, 'value')
    end

    nodes = {}
    @cib.elements.each('cib/configuration/nodes/node') do |n|
      uname = n.attributes['uname']
      state = :unclean
      ns = @cib.elements["cib/status/node_state[@uname='#{uname}']"]
      if ns
        state = crm_config[:stonith_enabled] ? determine_online_status_fencing(ns) : determine_online_status_no_fencing(ns)
        if state == :online
          standby = n.elements["instance_attributes/nvpair[@name='standby']"]
          # TODO(could): is the below actually a sane test?
          if standby && ['true', 'yes', '1', 'on'].include?(standby.attributes['value'])
            state = :standby
          end
        end
      end
      nodes[uname] = {
        :state => state
      }
    end

    resources = []
    @cib.elements.each('cib/configuration/resources/*') do |r|
      resources << get_resource(r)
    end

    # TODO(should): Can we just use cib attribute dc-uuid?  Or is that not viable
    # during cluster bringup, given we're using cibadmin -l?
    # Note that crmadmin will wait a long time if the cluster isn't up yet - cap it at 100ms
    dc = %x[/usr/sbin/crmadmin -t 100 -D 2>/dev/null].strip
    s = dc.rindex(' ')
    dc.slice!(0, s + 1) if s
    dc = _('Unknown') if dc.empty?

    # This blob is remarkably like the CIB, but staus is consolidated into the
    # main sections (nodes, resources) rather than being kept separate.
    render :json => {
      :meta => {
        :epoch  => "#{get_xml_attr(@cib.root, 'admin_epoch')}:#{get_xml_attr(@cib.root, 'epoch')}:#{get_xml_attr(@cib.root, 'num_updates')}",
        :dc     => dc
      },
      :crm_config => crm_config,
      :nodes => nodes,
      :resources => resources
      # also constraints, op_defaults, rsc_defaults, ...
    }
  end

  def update
    head :forbidden
  end

  def destroy
    head :forbidden
  end
end
