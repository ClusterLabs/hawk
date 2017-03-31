# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module ApplicationHelper
  def branding_config
    @branding_config ||= begin
      config = YAML.load_file(
        Rails.root.join(
          "config",
          "branding.yml"
        )
      )

      config.with_indifferent_access
    end
  end

  def meta_title
    @meta_title ||= begin
      [].tap do |output|
        output.push branding_config[:title]

        unless @title.empty?
          output.push @title
        end
      end.compact.join(": ")
    end
  end

  def page_title
    @page_title ||= begin
      @title
    end
  end

  def profile_title
    current_user || _("Profile")
  end

  def body_attrs
    hash_to_attrs(
        id: controller_name,
        class: current_cib.id,
        data: {
          cib: current_cib.id,
          epoch: current_cib.epoch,
          god: is_god?.to_s,
          user: current_user,
          content: current_cib.status.to_json
        }
    )
  end

  def hash_to_attrs(hash)
    # This simple helper method is used to convert a ruby hash into an HTML
    # attributes string
    # e.g: hash_to_attrs({class: "a", data: {cib: "b", epoch: "c"}) will return:
    # "class='a' data-cib='b' data-epoch='c'"
    hash.map{|key, value|
      value.is_a?(Hash) ? value.map { |k, v| "data-#{k}='#{html_escape(v)}'" } : "#{key}='#{html_escape(value)}'"
    }.join(" ").html_safe
  end

  def active_menu_with(*list)
    valid = if list.is_a? Array
      list
    else
      [list]
    end

    if valid.include? params[:controller].to_sym
      "active"
    end
  end

  def navbar_background_class
    "navbar-inverse"
  end

  def flash_class_for(type)
    case type.to_sym
    when :alert
      "alert-danger"
    else
      ["alert", type].join("-")
    end
  end

  def current_metatags
    [].tap do |output|
      if protect_against_forgery?
        output.push csrf_meta_tags
      end

      output.push tag(
        :meta,
        "name" => "keywords",
        "content" => ""
      )

      output.push tag(
        :meta,
        "name" => "description",
        "content" => ""
      )

      output.push tag(
        :meta,
        "content" => "IE=edge",
        "http-equiv" => "X-UA-Compatible"
      )

      output.push tag(
        :meta,
        "name" => "viewport",
        "content" => "width=device-width, initial-scale=1.0"
      )

      output.push tag(
        :meta,
        "charset" => "utf-8"
      )
    end.join("").html_safe
  end

  def localized_js
    [
      "locale",
      I18n.locale.to_s.gsub("-", "_")
    ].join("/")
  end

  def installed_docs
    [
      {
        title: "SLE HA Administration Guide",
        html: docs_path.join(
          "sle-ha-manuals_en",
          "index.html"
        ),
        pdf: docs_path.join(
          "sle-ha-guide_en-pdf",
          "book.sleha_en.pdf"
        ),
        desc: <<-EOS
          Introduces the product architecture and guides you through the setup,
          configuration, and administration of an HA cluster with SUSE Linux
          Enterprise High Availability Extension. Provides step-by-step
          instructions for key tasks, covering both graphical tools (like YaST
          or Hawk) and the command line interface (crmsh) in detail.
        EOS
      },
      {
        title: "HA NFS Storage with DRBD and Pacemaker",
        html: docs_path.join(
          "sle-ha-manuals_en",
          "art_ha_quick_nfs.html"
        ),
        pdf: docs_path.join(
          "sle-ha-nfs-quick_en-pdf",
          "art_ha_quick_nfs_en.pdf"
        ),
        desc: <<-EOS
          Describes how to set up a highly available NFS storage in a 2-node
          cluster with SLE HA, including the setup for DRBD and LVM2\u00AE.
        EOS
      },
      {
        title: "SLE HA GEO Clustering Quick Start",
        html: docs_path.join(
          "sle-ha-geo-manuals_en",
          "index.html"
        ),
        pdf: docs_path.join(
          "sle-ha-geo-quick_en-pdf",
          "art.ha.geo.quick_en.pdf"
        ),
        desc: <<-EOS
          Introduces the main components and displays a basic setup for
          geographically dispersed clusters (Geo clusters), including storage
          replication via DRBD\u00AE.
        EOS
      },
      {
        title: "Installation and Setup Quick Start",
        html: docs_path.join("installation-and-setup-quick-start", "index.html"),
        pdf: docs_path.join(
          "sle-ha-install-quick_en-pdf",
          "sle-ha-install-quick_en.pdf"
        ),
        desc: <<-EOS
          Guides you through the setup of a very basic two-node cluster,
using the bootstrap scripts provided by the ha-cluster-bootstrap package.
This includes the configuration of a virtual IP address as a cluster resource
and the user of SBD on shared storage as a fencing mechanism.
        EOS
      }
    ].select do |h|
      h[:html].exist? || h[:pdf].exist?
    end
  end

  def localized_help_for(section, subsection)
    [
      I18n.locale,
      :en_US,
      :en
    ].each do |locale|
      path = Rails.root.join(
        "config",
        "help",
        locale.to_s.dasherize,
        section.to_s,
        "#{subsection}.md"
      )

      next unless path.file?

      return markdown_help(
        path.read
      )
    end

    ""
  end

  def markdown_help(content)
    Kramdown::Document.new(
      content
    ).to_html.html_safe
  end

  def docs_path
    Rails.root.join("public", "doc")
  end

  def docs_link(doc, format)
    doc[format].to_s.gsub(
      Rails.root.join("public").to_s,
      ""
    )
  end

  def base_docs
    if Rails.configuration.x.hawk_is_sles
      [
        { icon: "bug", style: "danger", title: _("File a Bug Report"), desc: _("Report a bug or request a feature!"), url: "https://bugzilla.suse.com/enter_bug.cgi?classification=SUSE%20Linux%20Enterprise%20High%20Availability%20Extension" },
        { icon: "newspaper-o", style: "success", title: _("Release Notes"), desc: _("Read the release notes for the SUSE High Availability Extension."), url: "https://www.suse.com/releasenotes/x86_64/SLE-HA/12-SP2/" },
        { icon: "book", style: "success", title: _("Online Documentation"), desc: _("Read the most up-to-date documentation at the suse.com website."), url: "https://www.suse.com/documentation/sle-ha-12/" },
      ]
    else
      [
        { icon: "bug", style: "danger", title: _("File a Bug Report"), desc: _("Report a bug or request a feature!"), url: "https://github.com/ClusterLabs/hawk/issues/new" },
        { icon: "newspaper-o", style: "success", title: _("News"), desc: _("Visit the Hawk website for information about the latest release."), url: "http://hawk-ui.github.io/" },
        { icon: "book", style: "success", title: _("Online Documentation"), desc: _("Getting Started using Hawk"), url: "http://hawk-guide.readthedocs.io/en/latest/" },
      ]
    end
  end

  def footer_metadata_items
    meta_items = [
      [_("Status"), "meta.status", :status, nil],
      [_("Epoch"), "meta.epoch", :epoch, _("Current Configuration Version")],
      [_("Host"), "meta.host", :host, nil],
      [_("DC"), "meta.dc", :dc, _("Designated Coordinator")],
      [_("Schema"), "meta.validate_with", :validate_with, _("CIB Schema Version")],
      [_("Last Written"), "meta.cib_last_written", :cib_last_written],
      [_("Update Origin"), "meta.update_origin", :update_origin],
      [_("Update User"), "meta.update_user", :update_user],
      [_("Have Quorum"), "meta.have_quorum", :have_quorum],
      [_("Version"), "meta.version", :version, _("Pacemaker Version")],
      [_("Stack"), "meta.stack", :stack, _("Cluster Communication Stack")]
    ]
    meta = current_cib.meta
    ret = []
    meta_items.each do |item|
      ret.push [item[0], item[1], meta[item[2]], item[3]] if meta.key? item[2]
    end
    ret
  end

  def report_graph_image(id, transition)
    graph_path = graph_report_path(id: id, transition: transition, format: "svg", t: Time.now.to_i)
    link_to image_tag(graph_path, class: "img-thumbnail center-block", alt: _("Graph")), graph_path, target: "_blank"
  end

  def config_graph_image(cib_id)
    graph_path = cib_graph_path(cib_id: cib_id, format: "svg", t: Time.now.to_i)
    link_to image_tag(graph_path, class: "img-responsive center-block", alt: _("Graph")), graph_path, target: "_blank"
  end
end
