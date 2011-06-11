require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe MarilynRPC::ServiceCache do
  before(:each) do
    class DeferObjectMock
      attr_accessor :callback

      def callback(&block)
        @callback = block
      end

      def call(*args)
        @callback.call(*args)
      end
    end
  
    class TestService < MarilynRPC::Service
      attr_accessor :value
      register "/test"
      after_connect :init_value
      after_disconnect :change_value
      
      def init_value
        @value = false
      end
      
      def sync_method(a, b)
        a + b
      end
      
      def async_method(a, b)
        calc = DeferObjectMock.new
        MarilynRPC::Gentleman.new(calc) { |result| result }
      end
      
      def change_value
        @value = true
      end
    end
    
    @cache = MarilynRPC::ServiceCache.new
  end
  
  it "should be possible to make lookups and get the same instance" do
    [@cache.lookup("/test")].should == [@cache.lookup("/test")]
  end
  
  it "should not pe possible to get a unknown service" do
    lambda do
      @cache.lookup(:xxx)
    end.should raise_error(MarilynRPC::UnknownServiceError) 
  end
  
  it "should be possible to issue the disconnect! event from the cache" do
    expect do 
      @cache.disconnect!
    end.to(change(@cache.lookup("/test"), :value).from(false).to(true))
  end
  
  it "should be possible to call a sync method" do
    answer = @cache.call(envelope_call(1, "/test", :sync_method, 1, 2))
    answer = unpack_envelope(answer)
    answer.should be_a(MarilynRPC::CallResponseMail)
    answer.result.should == 3
  end
  
  it "should be possible to call an async method" do
    answer = @cache.call(envelope_call(1, "/test", :async_method, 1, 2))
    answer.should be_a(MarilynRPC::Gentleman)
    answer.tag.should == 1
  end
  
  context "authentication" do
    before(:each) do
      MarilynRPC::Service.authenticate_with do |username, password|
        username == "testuserid" && password == "secret"
      end
      
      class TestService < MarilynRPC::Service
        register "/test"
        authentication_required :secure

        def normal
          true
        end
        
        def username
          session_username
        end
        
        def logged_in?
          session_authenticated?
        end

        def secure
          true
        end
      end
      @cache = MarilynRPC::ServiceCache.new
    end
    
    it "should be possible to call the normal method" do
      answer = @cache.call(envelope_call(1, "/test", :normal))
      answer = unpack_envelope(answer)
      answer.result.should == true
    end
    
    it "should not be possible to call an secure method without authentication" do
      answer = @cache.call(envelope_call(1, "/test", :secure))
      answer = unpack_envelope(answer)
      answer.should be_a(MarilynRPC::ExceptionMail)
      answer.exception.should be_a(MarilynRPC::PermissionDeniedError)
    end
    
    it "should be possible to call an secure method with authentication" do
      @cache.call(envelope_call(1, MarilynRPC::Service::AUTHENTICATION_PATH, 
                                  :authenticate_plain, "testuserid", "secret"))
      answer = @cache.call(envelope_call(1, "/test", :secure))
      answer = unpack_envelope(answer)
      answer.result.should == true
    end
    
    it "should be possible to call the username from within the service without an authenticated user" do
      answer = @cache.call(envelope_call(1, "/test", :username))
      answer = unpack_envelope(answer)
      answer.result.should == nil
    end
    
    it "should be possible to call the username from within the service with an authenticated user" do
      @cache.username = "test"
      answer = @cache.call(envelope_call(1, "/test", :username))
      answer = unpack_envelope(answer)
      answer.result.should == "test"
    end
    
    it "should be possible to call the authentication from within the service" do
      answer = @cache.call(envelope_call(1, "/test", :logged_in?))
      answer = unpack_envelope(answer)
      answer.result.should == false
      
      # set the username
      @cache.username = "test"
      answer = @cache.call(envelope_call(1, "/test", :logged_in?))
      answer = unpack_envelope(answer)
      answer.result.should == true
    end
  end
end
