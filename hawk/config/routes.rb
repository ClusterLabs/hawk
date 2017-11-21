# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

Rails.application.routes.draw do
  root to: "pages#index"

  resources :cib, only: [] do
    get "/", via: [:get, :post, :options], to: "cib#show", as: ""
    match "/", via: [:options], to: "cib#show"
    match "/apply", as: :apply, to: 'cib#apply', via: [:get, :post]
    get "/ops/:id", to: "cib#ops", as: :ops

    get "/fencing", to: "fencing#index"
    get "/fencing/edit", to: "fencing#edit"
    post "/fencing/edit", to: 'fencing#edit', defaults: { format: 'json' }

    resources :nodes do
      member do
        get :online
        get :standby
        get :maintenance
        get :ready
        get :fence
        get :clearstate
        get :events
      end
    end

    resources :resources do
      member do
        get :start
        get :stop
        get :promote
        get :demote
        get :maintenance_on
        get :maintenance_off
        get :unmigrate
        get :migrate
        get :cleanup
        get :events
        get :edit_name
        post :update_name
      end

      collection do
        get :types
        get :status
      end
    end

    resources :primitives do
      member do
        get :copy
      end
    end
    resources :templates do
      member do
        get :copy
      end
    end

    resources :constraints do
      member do
        get :events
        get 'rename(/:to)', as: :rename, to: 'constraints#rename'
        post :rename, to: 'constraints#rename'
      end

      collection do
        get :types
        get :status
      end
    end

    resources :tickets do
      collection do
        get 'grant/:ticket', as: :grant, to: 'tickets#grant'
        get 'revoke/:ticket', as: :revoke, to: 'tickets#revoke'
      end
    end

    resources :clones
    resources :masters
    resources :locations
    resources :colocations
    resources :orders
    resources :groups
    resources :roles
    resources :users
    resources :tags
    resources :alerts

    resources :wizards do
      member do
        post :submit
      end
    end

    resource :config, only: [:show] do
      collection do
        get :edit
        get :meta
      end
    end
    resource :profile, only: [:edit, :update]
    resource :crm_config, only: [:edit, :update]

    resources :agents, only: [:show], constraints: { id: %r{[0-9A-Za-z:%@_\-\.\/]+} }

    resource :graph, only: [:show]

    resources :commands, only: [:index]
  end

  resources :reports, only: [:index, :destroy, :show] do
    collection do
      post :generate
      post :upload
      get :running, defaults: { format: 'json' }
      get :cancel, defaults: { format: 'json' }
    end

    member do
      get :display
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
  get '/sim/result', as: :sim_result, to: 'simulator#result', defaults: { format: 'json' }
  get '/sim/intervals/:id', as: :sim_intervals, to: 'simulator#intervals', defaults: { format: 'json' }
  get '/sim/help', as: :sim_help, to: 'simulator#help'

  resource :dashboard, only: [:show, :add, :remove] do
    member do
      get :add
      post :add
      post :remove
    end
  end

  get "help" => "pages#help", :as => :help

  get "logout" => "sessions#destroy", :as => :logout

  get "login" => "sessions#new", :as => :login
  match 'login' => "sessions#create", via: [ :post, :options], :as => :signin
  get "login/lang/:lang" => "sessions#lang", :as => :login_lang

  if Rails.env.production?
    get '*path' => redirect('/404.html') # if nothing else matches
  end
end
