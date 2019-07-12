# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module DashboardsHelper

  def javascript_for_clusters(clusters)
    clusters.map do |cluster|
      "dashboardAddCluster(#{cluster.to_json});"
    end.join("\n")
  end

  def escape_cluster_name(cluster_name)
    return "none" if cluster_name.blank?
    cluster_name.gsub(/[^0-9A-Za-z]/, '')
  end

end
