require "rails_helper"


RSpec.describe Api::V1::ResourcesController do

  context 'without a valid token' do
    before do
      @request.headers['Authorization'] = ""
      get 'index'
    end

    it 'returns a response with 401 status' do
      expect(response).to have_http_status 401
    end
  end



  context 'with a fake token' do
    before do
      @request.headers['Authorization'] = "Token token_string"
      get 'index'
    end

    it 'it returns a response with 401 status code' do
      expect(response).to have_http_status 401
    end
  end

end
