require File.dirname(__FILE__) + '/helper'

  describe 'Sipatra::Base subclasses' do
    class TestApp < Sipatra::Base
      invite // do
        proxy
      end
    end

    it 'processes requests with do_request' do
      TestApp::new.respond_to?(:do_request).should be_true

#      request = Rack::MockRequest.new(TestApp)
#      response = request.get('/')
#      assert response.ok?
#      assert_equal 'Hello World', response.body
    end
  end
