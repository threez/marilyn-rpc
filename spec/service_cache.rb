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
      register "/test"
      
      def sync_method(a, b)
        a + b
      end
      
      def async_method(a, b)
        calc = DeferObjectMock.new
        MarilynRPC::Gentleman.new(calc) { |result| result }
      end
    end
    @cache = MarilynRPC::ServiceCache.new
  end
  
  it "should be possible to call a sync method" do
    mail = MarilynRPC::CallRequestMail.new(1, "/test", :sync_method, [1, 2])
    answer = @cache.call(mail)
    answer.should be_a(MarilynRPC::CallResponseMail)
    answer.result.should == 3
  end
  
  it "should be possible to call an async method" do
    mail = MarilynRPC::CallRequestMail.new(1, "/test", :async_method, [1, 2])
    answer = @cache.call(mail)
    answer.should be_a(MarilynRPC::Gentleman)
    answer.tag.should == 1
  end
end
