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
      @services[path] = service.new
      @services[path].execute_after_connect_callback!
      return @services[path]
    else
      raise ArgumentError.new("Service #{path} unknown!")
    end
  end
  
  # issue the disconnect callbacks for all living services of this connection
  # @node this should only be called once by the server
  # @api private
  def call_after_disconnect_callbacks!
    @services.each do |path, service|
      service.execute_after_disconnect_callback!
    end
  end
end
