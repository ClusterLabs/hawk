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
  root to: "pages#index"

  resources :cib, only: [:show] do
    member do
      get action: "show"
      match action: "show", via: [:post, :options]
    end

    resources :nodes do
      member do
        get :online
        get :standby
        get :maintenance
        get :ready
        get :fence
        get :events
      end
    end

    resources :resources do
      member do
        get :start
        get :stop
        get :unmigrate
        get :promote
        get :demote
        get :cleanup
        get :manage
        get :unmanage
        get :migrate
        get :delete
        get :events
      end

      collection do
        get :types
        get :status
      end
    end

    resources :primitives do
      member do
        get :intervals
      end

      collection do
        get :options
      end
    end

    resources :constraints do
      member do
        get :events
      end

      collection do
        get :types
        get :status
      end
    end

    resources :tickets do
      member do
        get :grant
        get :revoke
      end
    end

    resources :clones
    resources :masters
    resources :wizards do
      member do
        post :submit
      end
    end
    resources :locations
    resources :colocations
    resources :orders
    resources :groups
    resources :templates
    resources :roles
    resources :users
    resources :tags

    resource :profile, only: [:edit, :update]
    resource :crm_config, only: [:edit, :update]

    resource :state, only: [:show]

    resource :checks, only: [] do
      collection do
        get :status
      end
    end

    resource :graph
  end

  resources :agents, only: [:show]

  scope :reports do
    resource :heartbeat

    resources :explorers, only: [:index, :destroy] do
      collection do
        post :generate
        post :upload
      end

      member do
        get ":page(.:format)" => "explorers#show", as: :show
        get ":page/detail(.:format)" => "explorers#detail", as: :detail
        get ":page/transition(.:format)" => "explorers#transition", as: :transition
        get ":page/diff(.:format)" => "explorers#diff", as: :diff
        get ":page/logs(.:format)" => "explorers#logs", as: :logs
      end
    end
  end

  post '/sim/run', as: :sim_run, to: 'simulator#run', defaults: { format: 'json' }
  post '/sim/reset', as: :sim_reset, to: 'simulator#reset', defaults: { format: 'json' }
  get '/sim/result', as: :sim_result, to: 'simulator#result', defaults: { format: 'json' }
  get '/sim/intervals/:id', as: :sim_intervals, to: 'simulator#intervals', defaults: { format: 'json' }

  resource :dashboard, only: [:show, :add, :remove] do
    member do
      get :add
      post :add
      post :remove
    end
  end

  get "monitor" => "pages#monitor", :as => :monitor
  get "help" => "pages#help", :as => :help

  get "logout" => "sessions#destroy", :as => :logout

  get "login" => "sessions#new", :as => :login
  match 'login' => "sessions#create", via: [ :post, :options], :as => :signin
end
