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

def mock_request(method, uri)
  unless @mock_request
    @mock_request = mock('MockSipRequest')
    @mock_request.should_receive(:method).any_number_of_times.and_return(method)
    @mock_request.should_receive(:requestURI).any_number_of_times.and_return(uri)
  end
  @mock_request
end

def mock_response
  @mock_response ||= mock('SipServletResponse')
end

describe Sipatra::Base do
  
  describe "within blocks" do
    class TestMethodsApp < Sipatra::Base
      invite /^sip:header$/ do
        header[:toto].should == 'test1'
        header['toto'].should == 'test1'
      end
      invite /^sip:headers$/ do
        headers[:toto].should == ['test1', 'test2']
        headers['toto'].should == ['test1', 'test2']
      end
      invite /^sip:address_header$/ do
        address_header[:toto].should == ['test1', 'test2']
        address_header['toto'].should == ['test1', 'test2']
      end
      invite /^sip:address_headers$/ do
        address_headers[:toto].should == ['test1', 'test2']
        address_headers['toto'].should == ['test1', 'test2']
      end
      invite /^sip:has_header$/ do
        header?(:toto).should == true
        header?('toto').should == true
      end
    end

    subject do
      TestMethodsApp::new
    end
  
    after(:each) do
      subject.do_request
    end
  
    it 'should respond to header[]' do
      subject.request = mock_request('INVITE', 'sip:header')
      subject.request.should_receive(:getHeader).exactly(2).with('toto').and_return('test1')
    end

    it 'should respond to headers[]' do
      subject.request = mock_request('INVITE', 'sip:headers')
      subject.request.should_receive(:getHeaders).exactly(2).with('toto').and_return(['test1', 'test2'])
    end

    it 'should respond to address_header[]' do
      subject.request = mock_request('INVITE', 'sip:address_header')
      subject.request.should_receive(:getAddressHeader).exactly(2).with('toto').and_return(['test1', 'test2'])
    end

    it 'should respond to address_headers[]' do
      subject.request = mock_request('INVITE', 'sip:address_headers')
      subject.request.should_receive(:getAddressHeaders).exactly(2).with('toto').and_return(['test1', 'test2'])
    end

    it 'should respond to header?' do
      subject.request = mock_request('INVITE', 'sip:has_header')
      subject.request.should_receive(:getHeader).exactly(2).with('toto').and_return('test1')
    end
  end
  
  describe "#send_response" do
    it 'should raise an ArgumentError when call with an incorrect symbol' do
      lambda { subject.send_response(:toto) }.should raise_exception(ArgumentError)
    end

    it 'should create a 404 status code when called with :not_found' do
      subject.request = mock_request('INVITE', 'sip:anything')

      subject.request.should_receive(:createResponse).with(404).and_return(mock_response)  
      mock_response.should_receive(:send)
      
      subject.send_response(:not_found)
    end
    
    it 'should respond to send_response with Integer' do
      subject.request = mock_request('INVITE', 'sip:anything')

      subject.request.should_receive(:createResponse).with(500).and_return(mock_response)  
      mock_response.should_receive(:send)

      subject.send_response(500)
    end
    
    it 'should respond to send_response with a block' do
      subject.request = mock_request('INVITE', 'sip:anything')

      subject.request.should_receive(:createResponse).with(500).and_return(mock_response)  
      mock_response.should_receive(:addHeader).with('Test1', 'Value1')
      mock_response.should_receive(:send)

      subject.send_response(500) do |response|
        response.addHeader('Test1', 'Value1')
      end
    end
    
    it 'should respond to send_response with a msg and block' do
      subject.request.should_receive(:createResponse).with(500, 'Error').and_return(mock_response)
      mock_response.should_receive(:addHeader).with('Test2', 'Value2')
      mock_response.should_receive(:send)
      
      subject.send_response(500, 'Error') do |response|
        response.addHeader('Test2', 'Value2')
      end      
    end

  end

end