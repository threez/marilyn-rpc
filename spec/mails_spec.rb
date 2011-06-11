require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "MarilynRPC Mails" do
  describe MarilynRPC::CallRequestMail do
    it "should be possible to serialize and deserialize a request" do
      tag = Time.now.to_f
      mail = MarilynRPC::CallRequestMail.new(
        tag, "/user", :find_by_name, ["mr.x"])
      data = mail.encode
      data.should include("find_by_name")
      mail = MarilynRPC::CallRequestMail.new()
      mail.decode(data)
      mail.tag.should == tag
      mail.path.should == "/user"
      mail.method.should == :find_by_name
      mail.args.should == ["mr.x"]
    end
  end
  
  describe MarilynRPC::CallResponseMail do
    before(:each) do
      class User < Struct.new(:name, :gid, :uid); end
    end
    
    it "should be possible to serialize and deserialize a request" do
      tag = Time.now.to_f
      result = [
        User.new("mr.x", 1, 1),
        User.new("mr.xxx", 1, 2)
      ]
      mail = MarilynRPC::CallResponseMail.new(tag, result)
      data = mail.encode
      data.should include("mr.xxx")
      mail = MarilynRPC::CallResponseMail.new
      mail.decode(data)
      mail.tag.should == tag
      mail.result.should == result
    end
  end
  
  describe MarilynRPC::ExceptionMail do
    it "should be possible to serialize and deserialize a request" do
      exception = nil
      begin
        raise Exception.new "TestError"
      rescue Exception => ex
        exception = ex
      end
      mail = MarilynRPC::ExceptionMail.new(123, exception)
      data = mail.encode
      data.should include("TestError")
      mail = MarilynRPC::ExceptionMail.new
      mail.decode(data)
      mail.tag.should == 123
      mail.exception.message.should == "TestError"
      mail.exception.backtrace.size.should > 1
    end
  end
  
  describe MarilynRPC::MailFactory do
    it "it should be possible to unpack mails encapsulated in envelopes" do
      tag = Time.now.to_f
      mail = MarilynRPC::CallRequestMail.new(
        tag, "/user", :find_by_name, ["mr.x"])
      envelope = MarilynRPC::Envelope.new(mail.encode, 
                                          MarilynRPC::CallRequestMail::TYPE)
      mail = MarilynRPC::MailFactory.unpack(envelope)
      mail.should be_a(MarilynRPC::CallRequestMail)
    end
  end
end
