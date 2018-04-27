require "rails_helper"


RSpec.describe Api::V1::ResourcesController do

  context 'without a valid token' do
    before do
      pass_fake_yaml_store
      @request.headers['Authorization'] = ""
      get 'index'
    end

    it 'returns a response with 401 status' do
      expect(response).to have_http_status 401
    end
  end



  context 'with a fake token' do
    before do
      pass_fake_yaml_store
      @request.headers['Authorization'] = "Token token_string"
      get 'index'
    end

    it 'it returns a response with 401 status code' do
      expect(response).to have_http_status 401
    end
  end



  context 'with a valid token', :cluster_env do
    before do
      pass_fake_yaml_store
      @request.headers['Authorization'] = "Token a123456789"
      get 'index'
    end

    it 'it returns a response with 200 status code' do
      expect(response).to have_http_status 200
    end
  end

end
