module MarilynRPC
  # Helper that gets mixed into the mail classes to make common things easyer
  module MailHelper
    SERIALIZER = Marshal
  end
  
  class CallRequestMail < Struct.new(:tag, :path, :method, :args)
    include MarilynRPC::MailHelper
    TYPE = 1
    
    def encode
      SERIALIZER.dump([self.tag, self.path, self.method, self.args])
    end
    
    def decode(data)
      self.tag, self.path, self.method, self.args = SERIALIZER.load(data)
    end
  end
  
  class CallResponseMail < Struct.new(:tag, :result)
    include MarilynRPC::MailHelper
    TYPE = 2
    
    def encode
      SERIALIZER.dump([self.tag, self.result])
    end
    
    def decode(data)
      self.tag, self.result = SERIALIZER.load(data)
    end
  end
  
  class ExceptionMail < Struct.new(:tag, :exception)
    include MarilynRPC::MailHelper
    TYPE = 3
    
    def encode
      SERIALIZER.dump([self.tag, self.exception])
    end
    
    def decode(data)
      self.tag, self.exception = SERIALIZER.load(data)
    end
  end
  
  # Helper to destiguish between the different mails
  module MailFactory
    include MarilynRPC::MailHelper
    
    # table which contains all types that can be unpacked
    TYPE_LOOK_UP = {
      MarilynRPC::CallRequestMail::TYPE   => MarilynRPC::CallRequestMail,
      MarilynRPC::CallResponseMail::TYPE  => MarilynRPC::CallResponseMail,
      MarilynRPC::ExceptionMail::TYPE     => MarilynRPC::ExceptionMail
    }
    
    # Parses the envelop and generate the correct mail.
    # @param [MarilynRPC::Envelope] envelope the envelope which contains a mail
    # @return [MarilynRPC::CallRequestMail, MarilynRPC::CallResponseMail,
    #          MarilynRPC::ExceptionMail] the mail object that was extracted
    def self.unpack(envelope)      
      if mail_klass = TYPE_LOOK_UP[envelope.type]
        mail = mail_klass.new(*SERIALIZER.load(envelope.content))
      else
        raise MarilynRPC::BrokenEnvelopeError.new \
          "The passed envelope is broken, no (correct) type!"
      end
    end
    
    # builds the binary data for a method call, it inlines some of the packing
    # for performance critical applications.
    # @param [Object] tag the tag for the object is relevate for multuplexing,
    #   it should be unique on a per conncetion base
    # @param [Object] path the path to identifiy the service
    # @param [Symbol, String] method the method name to call on the service
    # @param [Array<Object>] args the arguments that are passed to the remote
    #   side
    # @return [Object] the result of the call
    def self.build_call(tag, path, method, args)
      data = MarilynRPC::MailHelper::SERIALIZER.dump([tag, path, method, args])
      [
        data.size, MarilynRPC::CallRequestMail::TYPE
      ].pack(MarilynRPC::Envelope::HEADER_ENCODING) + data
    end
  end
end
