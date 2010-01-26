class MainController < ApplicationController
  #before_filter :ensure_login

  def initialize
    require 'socket'
    @host = Socket.gethostname  # should be short hostname

    # TODO: Need more deps than this (see crm)
    if File.exists?('/usr/sbin/crm_mon')
      if File.executable?('/usr/sbin/crm_mon')
        @crm_status = %x[/usr/sbin/crm_mon -s 2>&1].chomp
        # TODO: this is dubious (WAR: crm_mon -s giving "status: 1, output was: Warning:offline node: hex-14")
        if $?.exitstatus == 10 || $?.exitstatus == 11
          @err = _('%{cmd} failed (status: %{status}, output was: %{output})') %
                   {:cmd    => '/usr/sbin/crm_mon',
                    :status => $?.exitstatus,
                    :output => @crm_status }
        end
      else
        @err = _('Unable to execute %{cmd}') % {:cmd => '/usr/sbin/crm_mon' }
      end
    else
      @err = _('Pacemaker does not appear to be installed (%{cmd} not found)') %
               {:cmd => '/usr/sbin/crm_mon' }
    end
  end
  
  def get_property(doc, property, default = nil)
    # TODO: theoretically this xpath is a bit loose.
    e = doc.elements["//nvpair[@name='#{property}']"]
    e ? e.attributes['value'] : default
  end

  def get_cluster_status
    # TODO: error check this
    doc = REXML::Document.new(%x[/usr/sbin/cibadmin -Ql])

    # TODO: encapsulate all this in 'summary' hash
    @stack      = get_property(doc, 'cluster-infrastructure')
    @dc_version = get_property(doc, 'dc-version')
    # trim version back to 12 chars (same length hg usually shows),
    # enough to know what's going on, and less screen real-estate
    ver_trimmed = @dc_version.match(/.*-[a-f0-9]{12}/)
    @dc_version = ver_trimmed[0] if ver_trimmed
    # crmadmin will wait a long time if the cluster isn't up yet - cap it at 100ms
    @dc         = %x[/usr/sbin/crmadmin -t 100 -D 2>/dev/null].strip
    s = @dc.rindex(' ')
    @dc.slice!(0, s + 1) if s
    @dc = _('unknown') if @dc.empty?
    # default values per pacemaker 1.0 docs
    @stickiness = get_property(doc, 'default-resource-stickiness', '0') # TODO: is this documented?
    @stonith    = get_property(doc, 'stonith-enabled', 'true')
    @symmetric  = get_property(doc, 'symmetric-cluster', 'true')
    @no_quorum  = get_property(doc, 'no-quorum-policy', 'stop')

    # Possible node states (per print_status in crm_mon.c):
    #  - UNCLEAN (online)       (unclean && online)
    #  - UNCLEAN (pending)      (unclean && pending)
    #  - UNCLEAN (offline)      (unclean && none of the above)    
    #  - pending                (pending)
    #  - standby (on-fail)      (standby_onfail && online)
    #  - standby                (standby && online)
    #  - OFFLINE (standby)      (standby && !online)
    #  - online                 (online)
    #  - OFFLINE                (!online)
    # node_state attributes work as follows according to crm shell:
    #  - crmd="online" expected="member" join="member"  (online)
    #  - crmd="offline" expected=""                     (offline)
    #  - crmd="offline" expected="member"               (unclean)
    #

    @nodes = {}
    @expand_nodes = false
    # Have to use cib/configuration/nodes/node as authoritative source,
    # because cib/status/node_state doesn't exist yet if cluster is
    # coming online.
    doc.elements.each('cib/configuration/nodes/node') do |n|
      uname = n.attributes['uname']
      state = 'unclean'
      ns = doc.elements["cib/status/node_state[@uname='#{uname}']"]
      if ns
        # TODO: this is a bit rough...
        if ns.attributes['crmd'] == 'online'
          state = 'online'
          if ns.attributes['expected'] != 'member' || ns.attributes['join'] != 'member'
            # TODO: this may be considered a lie
            state = 'unclean'
          end
        else
          if ns.attributes['expected'] == 'member'
            state = 'unclean'
          elsif (ns.attributes['expected'] == ns.attributes['join']) || ns.attributes['expected'].empty?
            state = 'offline'
          else
            state = 'unclean'
          end
        end
        # figure out standby (god, what a mess)
        if state == 'online'
          n.elements.each('instance_attributes') do |ia|
            ia.elements.each('nvpair') do |p|
              if p.attributes['name'] == 'standby' &&
                 ['true', 'yes', '1', 'on'].include?(p.attributes['value'])
                # TODO: is the above actually a sane test?
                state = 'standby'
              end
            end
          end
        end
      end
      @nodes[uname] = { :state => state }
      # if anything is not online, expand by default
      @expand_nodes = true if state != 'online'
    end

    @expand_resources = false

    def resource_state(id)
      # TODO: unsafe string?
      m = %x[/usr/sbin/crm_resource -W -r #{id}].match(/is running on: (\S+)/)
      if m
        return m[1]
      else
        @expand_resources = true
        return nil
      end
    end

    def get_primitive(res, instance = nil)
      id = res.attributes['id']
      id += ":#{instance}" if instance
      {
        :id         => id,
        :restype    => res.name,
        :running_on => resource_state(id)
      }
    end

    @expand_groups = []

    def get_group(res, instance = nil)
      id = res.attributes['id']
      id += ":#{instance}" if instance
      # Arguably, the above is not really true (but we need it for DIV ids for collapsibles)
      # TODO: get rid of this, it's probably weird.  Also, make sure DIV ids only contain
      # valid characaters for HTML IDs and JavaScript strings, etc.
      children = []
      res.elements.each('primitive') do |p|
        c = get_primitive(p, instance)
        @expand_groups.push id unless c[:running_on]
        children.push c
      end
      {
        :id         => id,
        :restype    => res.name,
        :children   => children
      }
    end

    @expand_clones = []

    def get_clone(res)
      id = res.attributes['id']
      children = []
      # TODO: is this the correct way to determine clone instance IDs?
      clone_max = res.attributes['clone-max'] || @nodes.count
      if res.elements['primitive']
        for i in 0..clone_max.to_i-1 do
          c = get_primitive(res.elements['primitive'], i)
          @expand_clones.push id unless c[:running_on]
          children.push c
        end
      elsif res.elements['group']
        for i in 0..clone_max.to_i-1 do
          c = get_group(res.elements['group'], i)
          @expand_clones.push id if @expand_groups.include?(c[:id])
          children.push c
        end
      else
        # Again, this can't happen
      end
      {
        :id         => id,
        :restype    => res.name,
        :children   => children
      }
    end

    @resources = []
    doc.elements.each('cib/configuration/resources/*') do |res|
      case res.name
        when 'primitive'
          @resources.push get_primitive(res)
        when 'clone'
          @resources.push get_clone(res)
        when 'group'
          @resources.push get_group(res)
        else
          # This can't happen
          # TODO: whine
      end
    end

  end

  # Render cluster status by default
  # (can't just render :action => 'status',
  # or we don't get the instance variables)
  def index
    redirect_to :action => 'status'
  end

  def status
    @title = _('Cluster Status')
    
    get_cluster_status
    
    respond_to do |format|
      format.html # status.html.erb
      format.json { render :json => { :nodes => @nodes, :resources => @resources } }
    end
  end
  
end
