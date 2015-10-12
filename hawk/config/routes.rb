# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

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
        get :promote
        get :demote
        get :manage
        get :unmanage
        get :unmigrate
        get :migrate
        get :cleanup
      end

      collection do
        get :types
        get :status
      end
    end

    resources :primitives
    resources :templates

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

  get '/agent', as: :agent, to: 'agents#show'

  resources :reports, only: [:index, :destroy, :show] do
    collection do
      post :generate
      post :upload
      get :running, defaults: { format: 'json' }
    end

    member do
      get :download
      get ":transition/detail(.:format)" => "reports#detail", as: :detail, constraints: { transition: /\d+/ }
      get ":transition/cib(.:format)" => "reports#cib", as: :cib, constraints: { transition: /\d+/ }
      get ":transition/graph(.:format)" => "reports#graph", as: :graph, constraints: { transition: /\d+/ }
      get ":transition/diff(.:format)" => "reports#diff", as: :diff, constraints: { transition: /\d+/ }
      get ":transition/logs(.:format)" => "reports#logs", as: :logs, constraints: { transition: /\d+/ }
      get ":transition/pefile" => "reports#pefile", as: :pefile, constraints: { transition: /\d+/ }
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

  get "commands" => "pages#commands", :as => :commands

  match "monitor" => "monitor#monitor", :as => :monitor, via: [:get, :options], :as => :monitor
  get "help" => "pages#help", :as => :help

  get "logout" => "sessions#destroy", :as => :logout

  get "login" => "sessions#new", :as => :login
  match 'login' => "sessions#create", via: [ :post, :options], :as => :signin
end
