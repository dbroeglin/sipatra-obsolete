require File.dirname(__FILE__) + '/helper'

class FakeApp 
  include Sipatra::HelperMethods
end

describe 'When', Sipatra::HelperMethods, 'is included', FakeApp do
  def mock_address
    @mock_address ||= mock('Address')
  end
  
  def mock_proxy
    @mock_proxy ||= mock('Proxy')
  end
  
  def mock_sip_factory
    @sip_factory ||= mock('SipFactory')
  end
  
  before do
    subject.stub!(:request).and_return(Object::new)
  end

  describe "#convert_status_code" do
    it "should convert Integer to an Integer" do
      subject.send(:convert_status_code, 400).should be_kind_of(Integer)
    end
    
    it "should convert a Symbol to it's numeric equivalent" do
      subject.send(:convert_status_code, :not_found).should == 404
    end
  end
  
  describe "#remove_header" do
    it "should remove the header with the given name" do
      subject.request.should_receive(:removeHeader).exactly(2).with('toto')
      
      subject.remove_header(:toto)
      subject.remove_header('toto')
    end
  end
  
  describe "#create_address" do
    before do
      subject.stub!(:sip_factory => mock_sip_factory)
    end
    
    it "should create a wildcard address" do
      mock_sip_factory.should_receive(:createAddress).exactly(2).with('*').and_return(mock_address)
      
      subject.create_address('*').should == mock_address
      subject.create_address(:*).should == mock_address
    end
    
    it "should set expires on the address" do
      mock_sip_factory.should_receive(:createAddress).with('test').and_return(mock_address)
      mock_address.should_receive(:setExpires).with(1234)
      
      subject.create_address('test', :expires => 1234).should == mock_address
    end

    it "should set displayName on the address" do
      mock_sip_factory.should_receive(:createAddress).with('test').and_return(mock_address)
      mock_address.should_receive(:setDisplayName).with("display name")
      
      subject.create_address('test', :display_name => "display name").should == mock_address
    end
  end
  
  describe "#send_response" do    
    it 'should raise an ArgumentError when call with an incorrect symbol' do
      lambda { subject.send_response(:toto) }.should raise_exception(ArgumentError)
    end

    it 'should create a 404 status code when called with :not_found' do
      subject.request.should_receive(:createResponse).with(404).and_return(mock_response)  
      mock_response.should_receive(:send)
      
      subject.send_response(:not_found)
    end
    
    it 'should respond to send_response with Integer' do
      subject.request.should_receive(:createResponse).with(500).and_return(mock_response)  
      mock_response.should_receive(:send)

      subject.send_response(500)
    end
    
    it 'should respond to send_response with a block' do
      subject.request.should_receive(:createResponse).with(500).and_return(mock_response)  
      mock_response.should_receive(:addHeader).with('Test1', 'Value1')
      mock_response.should_receive(:send)

      subject.send_response(500) do |response|
        response.addHeader('Test1', 'Value1')
      end
    end

    it 'should respond to send_response with a Hash' do
      subject.request.should_receive(:createResponse).with(500).and_return(mock_response)  
      mock_response.should_receive(:addHeader).with('Test1', '1234')
      mock_response.should_receive(:send)

      subject.send_response 500, :Test1 => 1234
    end

    it 'should respond to send_response with a Hash and block' do
      subject.request.should_receive(:createResponse).with(500).and_return(mock_response)  
      mock_response.should_receive(:addHeader).with('Test1', 'Value1')
      mock_response.should_receive(:addHeader).with('Test2', 'Value2')
      mock_response.should_receive(:send)

      subject.send_response 500, :Test1 => 'Value1' do |response|
        response.addHeader('Test2', 'Value2')
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
  
  it 'should respond to header[]' do
    subject.request.should_receive(:getHeader).exactly(2).with('toto').and_return('test1')
    
    subject.header[:toto].should  == 'test1'
    subject.header['toto'].should == 'test1'
  end

  it 'should respond to header[]=' do
    subject.request.should_receive(:setHeader).exactly(2).with('toto', 'test2')
    
    subject.header[:toto]  = 'test2'
    subject.header['toto'] = 'test2'
  end
  
  it 'should respond to headers[]' do
    subject.request.should_receive(:getHeaders).exactly(2).with('toto').and_return(['test1', 'test2'])
    
    subject.headers[:toto].should == ['test1', 'test2']
    subject.headers['toto'].should == ['test1', 'test2']
  end

  it 'should not respond to headers[]=' do
    subject.headers.should_not respond_to('[]=')
  end

  it 'should respond to address_header[]' do
    subject.request.should_receive(:getAddressHeader).exactly(2).with('toto').and_return(['test1', 'test2'])
    
    subject.address_header[:toto].should == ['test1', 'test2']
    subject.address_header['toto'].should == ['test1', 'test2']
  end

  it 'should respond to address_header[]=' do
    subject.request.should_receive(:setAddressHeader).exactly(2).with('toto', 'test2')
    
    subject.address_header[:toto]  = 'test2'
    subject.address_header['toto'] = 'test2'
  end

  it 'should respond to address_headers[]' do
    subject.request.should_receive(:getAddressHeaders).exactly(2).with('toto').and_return(['test1', 'test2'])
    
    subject.address_headers[:toto].should == ['test1', 'test2']
    subject.address_headers['toto'].should == ['test1', 'test2']
  end

  it 'should not respond to address_headers[]=' do
    subject.address_headers.should_not respond_to('[]=')
  end

  it 'should respond to header?' do
    subject.request.should_receive(:getHeader).exactly(2).with('toto').and_return('test1')
    
    subject.header?(:toto).should == true
    subject.header?('toto').should == true
  end
  
  it 'should add a header' do
    subject.request.should_receive(:addHeader).exactly(2).with('toto', 'test2')

    subject.add_header(:toto, 'test2')
    subject.add_header('toto', 'test2')
  end
  
  it 'should add an address header' do
    subject.request.should_receive(:addAddressHeader).exactly(2).with('toto', 'test2')

    subject.add_address_header(:toto, 'test2')
    subject.add_address_header('toto', 'test2')
  end
  
  it 'should proxy without URI' do
    subject.request.should_receive(:requestURI).and_return('the_uri')
    subject.request.should_receive(:getProxy).and_return(mock_proxy)
    mock_proxy.should_receive(:proxyTo).with('the_uri')
    
    subject.proxy
  end
  
  it 'should proxy with an URI' do
    subject.request.should_receive(:getProxy).and_return(mock_proxy)
    subject.should_receive(:sip_factory).and_return(mock_sip_factory)
    mock_sip_factory.should_receive(:createURI).with('the_uri_string').and_return('the_uri')
    mock_proxy.should_receive(:proxyTo).with('the_uri')
    
    subject.proxy('the_uri_string')
  end  
end