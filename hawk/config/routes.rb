ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  map.resource :session

  map.resources :cib

  map.resources :cib, :has_many => :crm_config
  map.crm_config_info '/cib/:cib_id/crm_config/:id/info', :controller => 'crm_config', :action => 'info'

  map.resources :cib, :has_many => :primitives
  # TODO(should): Don't need primitive ID for these...
  map.primitives_types '/cib/:cib_id/primitives/new/types', :controller => 'primitives', :action => 'types'
  map.primitives_meta  '/cib/:cib_id/primitives/new/meta', :controller => 'primitives', :action => 'meta'

  # TODO(should): resources & nodes become Rails resources, look at RESTful routing
  # As of 2011-02-21 we now have a split here, resource editor uses the above
  map.with_options :controller => 'main' do |main|
    # status, etc.
    main.default      'main',              :action => 'index'
    main.index        'main/index',        :action => 'index'
    main.status       'main/status',       :action => 'status'
    main.gettext      'main/gettext',      :action => 'gettext'

    # resoruce ops
    main.resource_op  'main/resource/:op', :action => 'resource_op', :conditions => { :method => :post },
                      :op => /(start|stop|unmigrate|promote|demote|cleanup)/
    main.resource_migrate 'main/resource/migrate', :action => 'resource_migrate', :conditions => { :method => :post }

    # node ops
    main.node_standby 'main/node/:op',     :action => 'node_standby', :conditions => { :method => :post },
                      :op => /(standby|online)/
    main.node_fence   'main/node/fence',   :action => 'node_fence',  :conditions => { :method => :post }
  end

  map.root :controller => "main"

  map.login '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'

end
