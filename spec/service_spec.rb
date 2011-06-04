require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe MarilynRPC::Service do
  before(:each) do
    class TestService < MarilynRPC::Service
      register "/test"
    end
    
    class ExtendedTestService < MarilynRPC::Service
      register "/test/extended"
    end
  end
  
  it "should have to registered services" do
    MarilynRPC::Service.registry.size.should == 2
    MarilynRPC::Service.registry.should == {
      "/test/extended" => ExtendedTestService, 
      "/test" => TestService
    }
  end
end
