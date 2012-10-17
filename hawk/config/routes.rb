Hawk::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'main#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'

  resource :session
  resources :cib do
    resources :crm_config
    resources :resources
    resources :primitives
    resources :templates
    resources :groups
    resources :clones
    resources :masters
    resources :constraints
    resources :locations
    resources :colocations
    resources :orders
    resources :tickets
    resources :nodes
  end
  match '/cib/:cib_id/crm_config/:id/info' => 'crm_config#info', :as => :crm_config_info
  match '/cib/:cib_id/primitives/:id/monitor_intervals' => 'primitives#monitor_intervals', :as => :primitives_mi
  match '/cib/:cib_id/primitives/new/types' => 'primitives#types', :as => :primitives_types
  match '/cib/:cib_id/primitives/new/metadata' => 'primitives#metadata', :as => :primitives_metadata
  match '/cib/:cib_id/nodes/:id/events' => 'nodes#events', :as => :node_events
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
