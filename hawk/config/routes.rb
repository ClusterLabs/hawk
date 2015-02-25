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

Rails.application.routes.draw do
  root :to => 'pages#index'

  resource :session
  resources :cib, only: [:show] do
    resources :templates
    resources :groups
    resources :clones
    resources :masters
    resources :constraints
    resources :locations
    resources :colocations
    resources :orders
    resources :tickets



    resources :resources do
      member do
        get :events
      end
    end

    resources :primitives do
      member do
        get :events
      end
    end

    resources :nodes do
      member do
        get :events
      end
    end

    resources :roles
    resources :users

    resource :checks, only: [] do
      collection do
        get :status
      end
    end

    resource :settings, only: [:edit, :update]
    resource :crm_config, only: [:edit, :update]

    resource :dashboard, only: [:show]
  end

  match 'cib/:cib_id/primitives/:id/monitor_intervals' => 'primitives#monitor_intervals', :as => :primitives_mi, via: [:get, :post]
  match 'cib/:cib_id/primitives/new/types' => 'primitives#types', :as => :primitives_types, via: [:get, :post]
  match 'cib/:cib_id/primitives/new/metadata' => 'primitives#metadata', :as => :primitives_metadata, via: [:get, :post]
  match 'cib/:cib_id/nodes/:id/events' => 'nodes#events', :as => :node_events, via: [:get, :post]
  match 'cib/:cib_id/resources/:id/events' => 'resources#events', :as => :resource_events, via: [:get, :post]

  resources :hb_reports
  match 'hb_reports/new/status' => 'hb_reports#status', :as => :hb_reports_status, via: [:get, :post]

  match 'wizard' => 'wizard#run', :as => :wizard, via: [:get, :post]

  match 'explorer' => 'explorer#index', :as => :explorer, via: [:get, :post]
  match 'explorer/get' => 'explorer#get', :as => :pe_get, via: [:get, :post]
  match 'explorer/diff' => 'explorer#diff', :as => :pe_diff, via: [:get, :post]

  match 'main' => 'main#index', :as => :default, via: [:get, :post]
  match 'main/index' => 'main#index', :as => :index, via: [:get, :post]
  match 'main/status' => 'main#status', :as => :status, via: [:get, :post]
  match 'main/gettext' => 'main#gettext', :as => :gettext, via: [:get, :post]
  match 'main/resource/:op' => 'main#resource_op', :as => :resource_op, :op => /(start|stop|unmigrate|promote|demote|cleanup|manage|unmanage)/, via: [:post]
  match 'main/resource/migrate' => 'main#resource_migrate', :as => :resource_migrate, via: [:post]
  match 'main/resource/delete' => 'main#resource_delete', :as => :resource_delete, via: [:post]
  match 'main/node/:op' => 'main#node_standby', :as => :node_standby, :op => /(standby|online)/, via: [:post]
  match 'main/node/:op' => 'main#node_maintenance', :as => :node_maintenance, :op => /(maintenance|ready)/, via: [:post]
  match 'main/node/fence' => 'main#node_fence', :as => :node_fence, via: [:post]
  match 'main/ticket/grant' => 'main#ticket_grant', :as => :ticket_grant, via: [:post]
  match 'main/ticket/revoke' => 'main#ticket_revoke', :as => :ticket_revoke, via: [:post]
  match 'main/sim_reset' => 'main#sim_reset', :as => :sim_reset, via: [:get, :post]
  match 'main/sim_run' => 'main#sim_run', :as => :sim_run, via: [:get, :post]
  match 'main/sim_get' => 'main#sim_get', :as => :sim_get, via: [:get, :post]
  match 'main/graph_gen' => 'main#graph_gen', :as => :graph_gen, via: [:get, :post]
  match 'main/graph_get' => 'main#graph_get', :as => :graph_get, via: [:get, :post]

  match 'dashboard' => 'dashboard#index', :as => :dashboard, via: [:get, :post]

  get 'monitor' => 'pages#monitor', :as => :monitor
  get 'help' => 'pages#help', :as => :help
  get 'logout' => 'sessions#destroy', :as => :logout
  get 'login' => 'sessions#new', :as => :login

  post 'login' => 'sessions#create', :as => :signin
end
