require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe MarilynRPC::Gentleman do
  before(:each) do
    module MarilynRPC
      def self.serialize(obj)
        obj
      end
    end

    class DeferObjectMock
      attr_accessor :callback

      def callback(&block)
        @callback = block
      end

      def call(*args)
        @callback.call(*args)
      end
    end

    class ConnectionMock
      attr_accessor :data
      def send_mail(obj)
        @data = obj
      end
    end
  end
  
  it "should be possible to defer a process to a gentleman" do
    deferable = DeferObjectMock.new
    
    g = MarilynRPC::Gentleman.new(deferable) do |a, b|
      a + b
    end
    g.connection = ConnectionMock.new
    deferable.call(1, 2)
    g.connection.data.result.should == 3
  end
  
  it "should be possible to create a gentleman helper" do
    callback = nil
    
    g = MarilynRPC::Gentleman.proxy do |helper|
      callback = helper
    
      lambda do |a, b|
        a + b
      end
    end
    
    g.connection = ConnectionMock.new
    callback.call(1, 2)
    g.connection.data.result.should == 3
  end
end
