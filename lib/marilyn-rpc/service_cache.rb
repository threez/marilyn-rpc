class MarilynRPC::ServiceCache  
  # creates the service cache
  def initialize
    @services = {}
  end
  
  # call a service in the service cache
  # @param [MarilynRPC::CallRequestMail] mail the mail request object, that
  #   should be handled
  # @return [MarilynRPC::CallResponseMail, MarilynRPC::Gentleman] either a 
  #   Gentleman if the response is async or an direct response.
  def call(mail)
    # check if the correct mail object was send
    unless mail.is_a?(MarilynRPC::CallRequestMail)
      raise ArgumentError.new("Expected CallRequestMail Object!")
    end
    
    # call the service instance using the argument of the mail
    # puts "call #{mail.method}@#{mail.path} with #{mail.args.inspect}"
    result = lookup(mail.path).send(mail.method, *mail.args)
    # puts "result => #{result.inspect}"
    
    # no direct result, register callback
    if result.is_a? MarilynRPC::Gentleman
      result.tag = mail.tag # set the correct mail tag for the answer
      result
    else
      # make response
      MarilynRPC::CallResponseMail.new(mail.tag, result)
    end
  end
  
  # get the service from the cache or the service registry
  # @param [Object] path the path to the service (using the regestry)
  # @return [Object] the service object or raises an ArgumentError
  def lookup(path)
    # lookup the service in the cache
    if service = @services[path]
      return service
    # it's not in the cache, so try lookup in the service registry
    elsif service = MarilynRPC::Service.registry[path]
      return (@services[path] = service.new)
    else
      raise ArgumentError.new("Service #{mail.path} unknown!")
    end
  end
end
