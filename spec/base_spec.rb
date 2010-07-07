require File.dirname(__FILE__) + '/helper'

describe 'Sipatra::Base subclasses' do
  class TestApp < Sipatra::Base
    invite // do
      proxy
    end
  end

  it 'processes requests with do_request' do
    TestApp::new.respond_to?(:do_request).should be_true
  end
  
  it 'processes responses with do_response' do
    TestApp::new.respond_to?(:do_response).should be_true
  end
end

describe 'Sipatra::Base should have handlers for SIP request methods' do
  [:ack, :bye, :cancel, :info, :invite, :message, 
    :notify, :options, :prack, :publish, :refer, 
    :register, :subscribe, :update].each do |name|
    it "should accept method handler #{name}" do
      Sipatra::Base.respond_to?(name).should be_true
    end
  end 
  
  it "passes the subclass to configure blocks" do
    ref = nil
    TestApp.configure { |app| ref = app }
     ref.should == TestApp
  end   
end

class MockProxy
  def proxyTo(uri)
  end
end

class MockRequest
  attr_reader :method, :requestURI
  alias :getRequestURI :requestURI 
  
  def initialize(method, uri)
    @method, @requestURI = method.to_s.upcase, uri.to_s    
  end  
  
  def proxy
    MockProxy::new
  end
  
  alias :getProxy :proxy
end

describe 'Sipatra::Base instances' do
  class TestApp
    invite /sip:foo.*/ do
      respond_to?(:header).should be_true
      header.respond_to?("[]").should be_true
    end
  end
  
  it 'should respond to header[]' do
    app = TestApp::new
    app.request = MockRequest::new(:INVITE, 'sip:foo')
    app.do_request
  end
end