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

def mock_request(method, uri)
  request = mock('MockSipRequest')
  request.should_receive(:method).any_number_of_times.and_return(method)
  request.should_receive(:requestURI).any_number_of_times.and_return(uri)

  request
end

describe 'Sipatra::Base instances' do
  class TestMethodsApp < Sipatra::Base
    invite /^sip:header$/ do
      header[:toto].should == 'test1'
      header['toto'].should == 'test1'
    end
    invite /^sip:headers$/ do
      headers[:toto].should == ['test1', 'test2']
      headers['toto'].should == ['test1', 'test2']
    end
    invite /^sip:has_header$/ do
      header?(:toto).should == true
      header?('toto').should == true
    end
  end
  
  it 'should respond to header[]' do
    app = TestMethodsApp::new
    app.request = MockRequest::new(:INVITE, 'sip:header')
    app.request.should_receive(:getHeader).exactly(2).with('toto').and_return('test1')
    app.do_request
  end
  it 'should respond to headers[]' do
    app = TestMethodsApp::new
    app.request = mock_request('INVITE', 'sip:headers')
    app.request.should_receive(:getHeaders).exactly(2).with('toto').and_return(['test1', 'test2'])
    app.do_request
  end
  it 'should respond to header?' do
    app = TestMethodsApp::new
    app.request = mock_request('INVITE', 'sip:has_header')
    app.request.should_receive(:getHeader).exactly(2).with('toto').and_return('test1')
    app.do_request
  end
end