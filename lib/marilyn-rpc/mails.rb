module MarilynRPC
  # Helper that gets mixed into the mail classes to make common things easyer
  module MailHelper
    # generate a new serialize id which can be used in a mail
    # @param [Integer] a number between 0 and 254
    # @param [String] returns an 1 byte string as type id
    def self.type(nr)
      [nr].pack("c")
    end
    
    # extracts the real data and ignores the type information
    # @param [String] data the data to extract the mail from
    # @return [String] the extracted data
    def only_data(data)
      data.slice(1, data.size)
    end
    
    # serialize the data using marilyns default serializer
    # @param [Object] data the data to encode
    # @param [String] the serialized data
    def serialize(data)
      Marshal.dump(data)
    end
    
    # deserializes the passed data to the original objects
    # @param [String] data the serialized data
    # @return [Object] the deserialized object
    def deserialize(data)
      Marshal.load(data)
    end
  end
  
  class CallRequestMail < Struct.new(:tag, :path, :method, :args)
    include MarilynRPC::MailHelper
    TYPE = MarilynRPC::MailHelper.type(1)
    
    def encode
      TYPE + serialize([self.tag, self.path, self.method, self.args])
    end
    
    def decode(data)
      self.tag, self.path, self.method, self.args = deserialize(only_data(data))
    end
  end
  
  class CallResponseMail < Struct.new(:tag, :result)
    include MarilynRPC::MailHelper
    TYPE = MarilynRPC::MailHelper.type(2)
    
    def encode
      TYPE + serialize([self.tag, self.result])
    end
    
    def decode(data)
      self.tag, self.result = deserialize(only_data(data))
    end
  end
  
  class ExceptionMail < Struct.new(:exception)
    include MarilynRPC::MailHelper
    TYPE = MarilynRPC::MailHelper.type(3)
    
    def encode
      TYPE + serialize(self.exception)
    end
    
    def decode(data)
      self.exception = deserialize(only_data(data))
    end
  end
  
  # Helper to destiguish between the different mails
  module MailFactory
    # Parses the envelop and generate the correct mail.
    # @param [MarilynRPC::Envelope] envelope the envelope which contains a mail
    # @return [MarilynRPC::CallRequestMail, MarilynRPC::CallResponseMail,
    #          MarilynRPC::ExceptionMail] the mail object that was extracted
    def self.unpack(envelope)
      data = envelope.content
      type = data.slice(0, 1)
      case type
        when MarilynRPC::CallRequestMail::TYPE
          mail = MarilynRPC::CallRequestMail.new
        when MarilynRPC::CallResponseMail::TYPE
          mail = MarilynRPC::CallResponseMail.new
        when MarilynRPC::ExceptionMail::TYPE
          mail = MarilynRPC::ExceptionMail.new
        else
          raise ArgumentError.new("The passed type #{type.inspect} is unknown!")
      end  
      mail.decode(data)
      mail
    end
    
    # builds the binary data for a method call
    def self.build_call(tag, path, method_name, args)
      mail = MarilynRPC::CallRequestMail.new(tag, path, method_name, args)
      MarilynRPC::Envelope.new(mail.encode).encode
    end
  end
end
