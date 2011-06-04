require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe MarilynRPC::Server do
  before(:each) do
    class ConnectionStub
      include MarilynRPC::Server
      attr_accessor :data

      def initialize()
        @data = ""
      end

      def send_data(data)
        @data += data
      end
    end

    @server = ConnectionStub.new
  end
  
  it "should be possible to send multiple letters to the server" do
    @server.post_init
    @server.receive_data(MarilynRPC::Envelope.new("Test1").encode)
    envelope = MarilynRPC::Envelope.new
    envelope.parse!(@server.data)
    mail = MarilynRPC::ExceptionMail.new
    mail.decode(envelope.content)
    mail.exception.message.should == "The passed type \"T\" is unknown!"
    @server.receive_data(MarilynRPC::Envelope.new("Test2").encode)
    @server.receive_data(MarilynRPC::Envelope.new("Test3").encode)
    @server.unbind
  end
end
