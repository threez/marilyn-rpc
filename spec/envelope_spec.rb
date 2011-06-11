require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe MarilynRPC::Envelope do
  before(:each) do
    @envelope = MarilynRPC::Envelope.new
    @enc = MarilynRPC::Envelope::HEADER_ENCODING
  end
  
  it "should be possible to parse really small envelope pieces" do
    size = 100
    content = "X" * size
    data = [size, 1].pack(@enc) + content
    data.each_byte do |byte|
      overhang = @envelope.parse!(byte.chr)
      overhang.should == nil
    end
    @envelope.finished?.should == true
    @envelope.content.should == content
    @envelope.type.should == 1
  end
  
  it "should be possible to parse complete envelopes" do
    size = 100
    content = "X" * size
    overhang = @envelope.parse!([size, 1].pack(@enc) + content)
    overhang.should == nil
    @envelope.finished?.should == true
    @envelope.content.should == content
    @envelope.type.should == 1
  end
  
  it "shold be possible to parse an empty envelope" do
    overhang = @envelope.parse!([0, 1].pack(@enc))
    overhang.should == nil
    @envelope.content.should == ""
    @envelope.type.should == 1
    @envelope.finished?.should == true
  end
  
  it "should be possible to detect overhangs correctly" do
    content = "X" * 120
    overhang = @envelope.parse!([100, 1].pack(@enc) + content)
    overhang.should == "X" * 20
    @envelope.finished?.should == true
    @envelope.content.should == "X" * 100
    @envelope.type.should == 1
  end
  
  it "should be possible to lead an envelope from the overhang" do
    content = ([20, 1].pack(@enc) + ("X" * 20)) * 2
    overhang = @envelope.parse!(content)
    overhang.should == ([20, 1].pack(@enc) + ("X" * 20))
    @envelope.finished?.should == true
    @envelope.content.should == "X" * 20
    @envelope.type.should == 1
    @envelope = MarilynRPC::Envelope.new
    overhang = @envelope.parse!(overhang)
    overhang.should == nil
    @envelope.finished?.should == true
    @envelope.content.should == "X" * 20
    @envelope.type.should == 1
  end
  
  it "should be possible to @encode a envelope correctly" do
    content = "Hallo Welt"
    @envelope.content = content
    @envelope.type = 1
    @envelope.encode.should == [content.size, 1].pack(@enc) + content
  end
  
  it "should be possible to create a envelope using the initalizer" do
    size = 100
    content = "X" * size
    @envelope = MarilynRPC::Envelope.new(content, 1)
    @envelope.finished?.should == true
    @envelope.content.should == content
    @envelope.type == 1
  end
end
