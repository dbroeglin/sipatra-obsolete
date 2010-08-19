require File.dirname(__FILE__) + '/helper'

class FakeApp 
  include Sipatra::HelperMethods
end

describe 'When', Sipatra::HelperMethods, 'is included', FakeApp do
  def mock_address
    @mock_address ||= mock('Address')
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
  
  describe "#create_address" do
    before do
      @sip_factory = mock('SipFactory')
      subject.stub!(:sip_factory => @sip_factory)
    end
    
    it "should create a wildcard address" do
      @sip_factory.should_receive(:createAddress).exactly(2).with('*').and_return(mock_address)
      
      subject.create_address('*').should == mock_address
      subject.create_address(:*).should == mock_address
    end
    
    it "should set expires on the address" do
      @sip_factory.should_receive(:createAddress).with('test').and_return(mock_address)
      mock_address.should_receive(:setExpires).with(1234)
      
      subject.create_address('test', :expires => 1234).should == mock_address
    end

    it "should set displayName on the address" do
      @sip_factory.should_receive(:createAddress).with('test').and_return(mock_address)
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
    
    subject.header[:toto].should == 'test1'
    subject.header['toto'].should == 'test1'
  end
  
  it 'should respond to headers[]' do
    subject.request.should_receive(:getHeaders).exactly(2).with('toto').and_return(['test1', 'test2'])
    
    subject.headers[:toto].should == ['test1', 'test2']
    subject.headers['toto'].should == ['test1', 'test2']
  end

  it 'should respond to address_header[]' do
    subject.request.should_receive(:getAddressHeader).exactly(2).with('toto').and_return(['test1', 'test2'])
    
    subject.address_header[:toto].should == ['test1', 'test2']
    subject.address_header['toto'].should == ['test1', 'test2']
  end

  it 'should respond to address_headers[]' do
    subject.request.should_receive(:getAddressHeaders).exactly(2).with('toto').and_return(['test1', 'test2'])
    
    subject.address_headers[:toto].should == ['test1', 'test2']
    subject.address_headers['toto'].should == ['test1', 'test2']
  end

  it 'should respond to header?' do
    subject.request.should_receive(:getHeader).exactly(2).with('toto').and_return('test1')
    
    subject.header?(:toto).should == true
    subject.header?('toto').should == true
  end
end