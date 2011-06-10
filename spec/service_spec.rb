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
    MarilynRPC::Service.__registry__.size.should >= 2
    MarilynRPC::Service.__registry__["/test/extended"].should == ExtendedTestService
    MarilynRPC::Service.__registry__["/test"].should == TestService
  end
  
  context "callbacks" do
    before(:each) do
      class ExtendedTestService < MarilynRPC::Service
        attr_reader :value
        after_connect :connect
        after_disconnect :disconnect
        
        def connect
          @value = :connect
        end
        
        def disconnect
          @value = :disconnect
        end
      end
      @service = ExtendedTestService.new
    end
    
    it "should be possible to register a after_connect callback" do
      expect do 
        @service.__run_callbacks__(:after_connect)
      end.to(change(@service, :value).from(nil).to(:connect))
      
    end
    
    it "should be possible to register a after_disconnect callback" do
      expect do 
        @service.__run_callbacks__(:after_disconnect)
      end.to(change(@service, :value).from(nil).to(:disconnect))
    end
  end
  
  context "authentication" do
    before(:each) do
      class ExtendedTestService < MarilynRPC::Service
        authentication_required :secure
        
        def normal
          true
        end
        
        def secure
          false
        end
      end
      @service = ExtendedTestService.new
    end
    
    it "should be possible to find the secure method in the auth. hash" do
      @service.class.__methods_with_authentication__[:secure].should be_true
    end
  end
end
