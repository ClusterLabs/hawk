#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2015 SUSE LLC, All Rights Reserved.
#
# Author: Tim Serong <tserong@suse.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it would be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Further, this software is distributed without any warranty that it is
# free of the rightful claim of any third person regarding infringement
# or the like.  Any license provided herein, whether implied or
# otherwise, applies only to this software file.  Patent licenses, if
# any, provided herein do not apply to combinations of this program with
# other software, or any other product whatsoever.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston MA 02111-1307, USA.
#
#======================================================================

module ApplicationHelper
  def branding_config
    @branding_config ||= begin
      config = YAML.load_file(
        Rails.root.join(
          'config',
          'branding.yml'
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
      end.compact.join(': ')
    end
  end

  def page_title
    @page_title ||= begin
      @title
    end
  end

  def body_attrs
    {
      id: controller_name,
      class: current_cib.id,
      data: {
        cib: current_cib.id,
        monitor: current_cib.epoch
      }
    }
  end

  def active_menu_with(list)
    valid = if list.is_a? Array
      list
    else
      [list]
    end

    if valid.include? params[:controller].to_sym
      'active'
    else
      nil
    end
  end

  def flash_class_for(type)
    case type.to_sym
    when :alert
      'alert-danger'
    else
      ['alert', type].join('-')
    end
  end

  def current_metatags
    [].tap do |output|
      if protect_against_forgery?
        output.push csrf_meta_tags
      end

      output.push tag(
        :meta,
        'name' => 'keywords',
        'content' => ''
      )

      output.push tag(
        :meta,
        'name' => 'description',
        'content' => ''
      )

      output.push tag(
        :meta,
        'content' => 'IE=edge',
        'http-equiv' => 'X-UA-Compatible'
      )

      output.push tag(
        :meta,
        'name' => 'viewport',
        'content' => 'width=device-width, initial-scale=1.0'
      )

      output.push tag(
        :meta,
        'charset' => 'utf-8'
      )
    end.join('').html_safe
  end

  def localized_js
    [
      'locale',
      I18n.locale.to_s.gsub('-', '_')
    ].join('/')
  end

  def installed_docs
    [
      {
        title: 'SLE HA Administration Guide',
        html: docs_path.join(
          'sle-ha-manuals_en',
          'index.html'
        ),
        pdf: docs_path.join(
          'sle-ha-guide_en-pdf',
          'book.sleha_en.pdf'
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
        title: 'HA NFS Storage with DRBD and Pacemaker',
        html: docs_path.join(
          'sle-ha-manuals_en',
          'art_ha_quick_nfs.html'
        ),
        pdf: docs_path.join(
          'sle-ha-nfs-quick_en-pdf',
          'art_ha_quick_nfs_en.pdf'
        ),
        desc: <<-EOS
          Describes how to set up a highly available NFS storage in a 2-node
          cluster with SLE HA, including the setup for DRBD and LVM2\u00AE.
        EOS
      },
      {
        title: 'SLE HA GEO Clustering Quick Start',
        html: docs_path.join(
          'sle-ha-geo-manuals_en',
          'index.html'
        ),
        pdf: docs_path.join(
          'sle-ha-geo-quick_en-pdf',
          'art.ha.geo.quick_en.pdf'
        ),
        desc: <<-EOS
          Introduces the main components and displays a basic setup for
          geographically dispersed clusters (Geo clusters), including storage
          replication via DRBD\u00AE.
        EOS
      }
    ].select do |h|
      h[:html].exist? || h[:pdf].exist?
    end
  end

  def docs_path
    Rails.root.join('public', 'doc')
  end

  def docs_link(doc, format)
    doc[format].to_s.gsub(
      Rails.root.join('public').to_s,
      ''
    )
  end
end
