# # This class represents a per connection cache of the service instances.
# @attr [String, nil] username the username of a authenticated user oder `nil`
class MarilynRPC::ServiceCache
  attr_accessor :username
  
  # creates the service cache
  def initialize
    @services = {}
  end
  
  # call a service in the service cache
  # @param [MarilynRPC::Envelope] envelope the envelope that contains the
  #   request subject (mail), that should be handled
  # @return [MarilynRPC::CallResponseMail, MarilynRPC::Gentleman] either a 
  #   Gentleman if the response is async or an direct response.
  def call(envelope)
    mail = MarilynRPC::MailFactory.unpack(envelope)
    tag = mail.tag
    
    if mail.is_a?(MarilynRPC::CallRequestMail) # handle a call request
      # fetch the service and check if the user has the permission to access the
      # service
      service = lookup(mail.path)
      method = mail.method.to_sym
      if service.class.__methods_with_authentication__[method] && !@username 
        raise MarilynRPC::PermissionDeniedError.new("No permission to access" \
              " the #{service.class.name}##{method}")
      end
  
      # call the service instance using the argument of the mail
      #puts "call #{mail.method}@#{mail.path} with #{mail.args.inspect}"
      result = service.__send__(method, *mail.args)
      #puts "result => #{result.inspect}"
  
      # no direct result, register callback
      if result.is_a? MarilynRPC::Gentleman
        result.tag = tag # set the correct mail tag for the answer
        result
      else # direct response
        MarilynRPC::Envelope.new(MarilynRPC::CallResponseMail.new(tag, result).encode, 
                                 MarilynRPC::CallResponseMail::TYPE).encode
      end
    else
      raise MarilynRPC::BrokenEnvelopeError.new("Expected CallRequestMail Object!")
    end
  rescue MarilynRPC::BrokenEnvelopeError => exception
    MarilynRPC::Envelope.new(MarilynRPC::ExceptionMail.new(nil, exception).encode, 
                             MarilynRPC::ExceptionMail::TYPE).encode
  rescue => exception
    #puts exception
    #puts exception.backtrace.join("\n   ")
    MarilynRPC::Envelope.new(MarilynRPC::ExceptionMail.new(tag, exception).encode, 
                             MarilynRPC::ExceptionMail::TYPE).encode
  end
  
  # get the service from the cache or the service registry
  # @param [Object] path the path to the service (using the regestry)
  # @return [Object] the service object or raises an ArgumentError
  def lookup(path)
    # lookup the service in the cache
    if service = @services[path]
      return service
    # it's not in the cache, so try lookup in the service registry
    elsif service = MarilynRPC::Service.__registry__[path]
      @services[path] = service.new
      @services[path].service_cache = self
      @services[path].__run_callbacks__(:after_connect)
      return @services[path]
    else
      raise MarilynRPC::UnknownServiceError.new("Service #{path} unknown!")
    end
  end
  
  # issue the disconnect callbacks for all living services of this connection
  # @node this should only be called once by the server
  # @api private
  def disconnect!
    @services.each do |path, service|
      service.__run_callbacks__(:after_disconnect)
    end
  end
end
