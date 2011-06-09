# This class handles the envelope parsing and encoding which will be used by the
# server to handle multiple writes into the envelope.
class MarilynRPC::Envelope
  # size of the envelope content
  attr_reader :size
  
  # create a new envelope instance
  # @param [String] content the content of the new envelope
  def initialize(content = nil)
    self.content = content
  end
  
  # parses the passed data
  # @param [String] data parses the parsed data
  # @return [String,nil] returns data that is not part of this string 
  #   (in case the) parser gets more data than the length of the envelope. 
  #   In case there are no data it will return nil.
  def parse!(data)
    @buffer += data
    overhang = nil

    if @size.nil?
      # parse the length field of the 
      # extract 4 bytes length header
      @size = @buffer.slice!(0...4).unpack("N").first if @buffer.size >= 4 
    else
      # envelope is complete and contains overhang
      overhang = @buffer.slice!(@size, @buffer.size) if @buffer.size > @size
    end
    
    overhang
  end
  
  # returns the content of the envelope
  # @note should only be requested when the message if {finished?}.
  # @return [String] the content of the envelope
  def content
    @buffer
  end
  
  # sets the content of the envelope. If `nil` was passed an empty string will
  # be set.
  # @param [String] data the new content
  def content=(content)
    @buffer = content || ""
    @size = content.nil? ? nil : content.size
  end
  
  # encodes the envelope to be send over the wire
  # @return [String] encoded envelope
  def encode
    [@size].pack("N") + @buffer
  end

  # checks if the complete envelope was allready parsed
  # @return [Boolean] `true` if the message was parsed
  def finished?
    @buffer.size == @size
  end
end
