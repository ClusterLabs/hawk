Hawk::Application.routes.draw do
  resource :session
  resources :cib
  resources :cib
  match '/cib/:cib_id/crm_config/:id/info' => 'crm_config#info', :as => :crm_config_info
  resources :cib
  match '/cib/:cib_id/primitives/:id/monitor_intervals' => 'primitives#monitor_intervals', :as => :primitives_mi
  match '/cib/:cib_id/primitives/new/types' => 'primitives#types', :as => :primitives_types
  match '/cib/:cib_id/primitives/new/metadata' => 'primitives#metadata', :as => :primitives_metadata
  resources :cib
  resources :cib
  resources :cib
  resources :cib
  resources :cib
  resources :cib
  resources :cib
  resources :cib
  resources :cib
  resources :cib
  match '/cib/:cib_id/nodes/:id/events' => 'nodes#events', :as => :node_events
  resources :cib
  match '/cib/:cib_id/resources/:id/events' => 'resources#events', :as => :resource_events
  resources :hb_reports
  match '/hb_reports/new/status' => 'hb_reports#status', :as => :hb_reports_status
  match '/wizard' => 'wizard#run', :as => :wizard
  match 'explorer' => 'explorer#index', :as => :explorer
  match 'explorer/get' => 'explorer#get', :as => :pe_get
  match 'main' => 'main#index', :as => :default
  match 'main/index' => 'main#index', :as => :index
  match 'main/status' => 'main#status', :as => :status
  match 'main/gettext' => 'main#gettext', :as => :gettext
  match 'main/resource/:op' => 'main#resource_op', :as => :resource_op, :op => /(start|stop|unmigrate|promote|demote|cleanup)/, :via => :post
  match 'main/resource/migrate' => 'main#resource_migrate', :as => :resource_migrate, :via => :post
  match 'main/resource/delete' => 'main#resource_delete', :as => :resource_delete, :via => :post
  match 'main/node/:op' => 'main#node_standby', :as => :node_standby, :op => /(standby|online)/, :via => :post
  match 'main/node/fence' => 'main#node_fence', :as => :node_fence, :via => :post
  match 'main/sim_reset' => 'main#sim_reset', :as => :sim_reset
  match 'main/sim_run' => 'main#sim_run', :as => :sim_run
  match 'main/sim_get' => 'main#sim_get', :as => :sim_get
  match '/' => 'main#index'
  match '/login' => 'sessions#new', :as => :login
  match '/logout' => 'sessions#destroy', :as => :logout
end
