require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe MarilynRPC::Envelope do
  before(:each) do
    @envelope = MarilynRPC::Envelope.new
  end
  
  it "should be possible to parse really small envelope pieces" do
    size = 100
    content = "X" * size
    data = [size].pack("N") + content
    data.each_byte do |byte|
      overhang = @envelope.parse!(byte.chr)
      overhang.should == nil
    end
    @envelope.finished?.should == true
    @envelope.content.should == content
  end
  
  it "should be possible to parse complete envelopes" do
    size = 100
    content = "X" * size
    overhang = @envelope.parse!([size].pack("N") + content)
    overhang.should == nil
    @envelope.finished?.should == true
    @envelope.content.should == content
  end
  
  it "shold be possible to parse an empty envelope" do
    overhang = @envelope.parse!([0].pack("N"))
    overhang.should == nil
    @envelope.content.should == ""
    @envelope.finished?.should == true
  end
  
  it "should be possible to detect overhangs correctly" do
    content = "X" * 120
    overhang = @envelope.parse!([100].pack("N") + content)
    overhang.should == "X" * 20
    @envelope.finished?.should == true
    @envelope.content.should == "X" * 100
  end
  
  it "should be possible to lead an envelope from the overhang" do
    content = ([20].pack("N") + ("X" * 20)) * 2
    overhang = @envelope.parse!(content)
    overhang.should == ([20].pack("N") + ("X" * 20))
    @envelope.finished?.should == true
    @envelope.content.should == "X" * 20
    @envelope = MarilynRPC::Envelope.new
    overhang = @envelope.parse!(overhang)
    overhang.should == nil
    @envelope.finished?.should == true
    @envelope.content.should == "X" * 20
  end
  
  it "should be possible to encode a envelope correctly" do
    content = "Hallo Welt"
    @envelope.content = content
    @envelope.encode.should == [content.size].pack("N") + content
  end
  
  it "should be possible to create a envelope using the initalizer" do
    size = 100
    content = "X" * size
    @envelope = MarilynRPC::Envelope.new(content)
    @envelope.finished?.should == true
    @envelope.content.should == content
  end
end
