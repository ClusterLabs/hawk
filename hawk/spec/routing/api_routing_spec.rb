require "rails_helper"


describe "api_routing", type: :routing do

  it "routes /api/v1/status to api/v1/status#index" do
    expect( :get => "/api/v1/status").to route_to(
            :controller => "api/v1/status",
            :action => "index"
          )
  end

  it "routes /api/v1/cluster to api/v1/cluster#index" do
    expect( :get => "/api/v1/cluster").to route_to(
            :controller => "api/v1/cluster",
            :action => "index"
    )
  end

  it "routes /api/v1/resources to api/v1/resources#index" do
    expect( :get => "/api/v1/resources").to route_to(
            :controller => "api/v1/resources",
            :action => "index"
    )
  end

  it "routes /api/v1/resources/id to api/v1/resources#show" do
    expect( :get => "/api/v1/resources/id").to route_to(
            :controller => "api/v1/resources",
            :action => "show",
            :id => "id"
    )
  end

  it "routes /api/v1/nodes to api/v1/nodes#index" do
    expect( :get => "/api/v1/nodes").to route_to(
            :controller => "api/v1/nodes",
            :action => "index"
    )
  end

  it "routes /api/v1/nodes/id to api/v1/nodes#show" do
    expect( :get => "/api/v1/nodes/id").to route_to(
            :controller => "api/v1/nodes",
            :action => "show",
            :id => "id"
    )
  end

end
