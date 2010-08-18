require File.dirname(__FILE__) + '/helper'

class TestHelperMethods
  include Sipatra::HelperMethods
end


describe TestHelperMethods do

  def mock_address
    @mock_address ||= mock('Address')
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
end