module ApplicationHelper
  def inject_linebreaks(e)
    lines = e.split("\n").each{|line| h(line)}.join('<br/>')
  end

  def installed_documentation
    def file_or_nil(f)
      File.exists?("#{Rails.root}/public#{f}") ? f : nil
    end

    [
      {
        :title => "SLE HA Administration Guide",
        :html => file_or_nil("/doc/sle-ha-manuals_en/index.html"),
        :pdf  => file_or_nil("/doc/sle-ha-guide_en-pdf/book.sleha_en.pdf"),
        :desc  => <<-eos
          Introduces the product architecture and guides you through the setup,
          configuration, and administration of an HA cluster with SUSE Linux Enterprise
          High Availability Extension. Provides step-by-step instructions for key tasks,
          covering both graphical tools (like YaST or Hawk) and the command line
          interface (crmsh) in detail.
        eos
      },
      {
        :title => "Highly Available NFS Storage with DRBD and Pacemaker",
        :html => file_or_nil("/doc/sle-ha-manuals_en/art_ha_quick_nfs.html"),
        :pdf  => file_or_nil("/doc/sle-ha-nfs-quick_en-pdf/art_ha_quick_nfs_en.pdf"),
        :desc  => <<-eos
          Describes how to set up a highly available NFS storage in a 2-node cluster with
          SLE HA, including the setup for DRBD and LVM2\u00AE.
        eos
      },
      {
        :title => "SLE HA GEO Clustering Quick Start",
        :html => file_or_nil("/doc/sle-ha-geo-manuals_en/index.html"),
        :pdf  => file_or_nil("/doc/sle-ha-geo-quick_en-pdf/art.ha.geo.quick_en.pdf"),
        :desc => <<-eos
          Introduces the main components and displays a basic setup for geographically
          dispersed clusters (Geo clusters), including storage replication via DRBD\u00AE.
        eos
      }
    ].select {|h| h[:html] || h[:pdf] }
  end
end
