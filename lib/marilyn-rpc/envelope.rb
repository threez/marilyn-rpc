# This class handles the envelope parsing and encoding which will be used by the
# server to handle multiple writes into the envelope.
class MarilynRPC::Envelope
  HEADER_SIZE = 5
  HEADER_ENCODING = "NC".freeze
  
  # size of the envelope content
  attr_reader :size
  
  # the type of mail that is in the envelope
  attr_accessor :type
  
  # create a new envelope instance
  # @param [String] content the content of the new envelope
  # @param [String] type the type of content
  def initialize(content = nil, type = nil)
    self.content = content
    @type = type
  end
  
  # resets the envelope object to contain no data, like if it was newly created
  def reset!
    @buffer, @size, @type = "", nil, nil
  end
  
  # parses the passed data
  # @param [String] data parses the parsed data
  # @return [String,nil] returns data that is not part of this string 
  #   (in case the) parser gets more data than the length of the envelope. 
  #   In case there are no data it will return nil.
  def parse!(data)
    @buffer += data

    # parse the length field of the 
    if @size == nil && @buffer.size >= HEADER_SIZE
      parse_header!(@buffer.slice!(0...HEADER_SIZE))
    end
    
    # envelope is complete and contains overhang
    if @size && @buffer.size > @size
      return @buffer.slice!(@size, @buffer.size) # returns the overhang
    end
  end
  
  # parses the header without having much checking overhead. This is useful in
  # situations where we can assure the size beforehand
  # @param [String] header the header byte string of size {HEADER_SIZE}
  # @api private
  def parse_header!(header)
    @size, @type = header.unpack(HEADER_ENCODING)
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
    [@size, @type].pack(HEADER_ENCODING) + @buffer
  end

  # checks if the complete envelope was allready parsed
  # @return [Boolean] `true` if the message was parsed
  def finished?
    @buffer.size == @size
  end
end
