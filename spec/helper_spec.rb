require File.dirname(__FILE__) + '/helper'

class TestHelperMethods
  include Sipatra::HelperMethods
end

describe TestHelperMethods do
  describe "#convert_status_code" do
    it "should convert Integer to an Integer" do
      subject.send(:convert_status_code, 400).should be_kind_of(Integer)
    end
    
    it "should convert a Symbol to it's numeric equivalent" do
      subject.send(:convert_status_code, :not_found).should == 404
    end
  end
end