# A class with nothing but `__send__`, `__id__`, `class` and `public_methods`.
class ServiceBlankSlate
  instance_methods.each { |m| undef_method m unless m =~ /^__|public_methods|class|object_id/ }
end 

# This class represents the base for all events, it is used for registering
# services and defining callbacks for certain service events. It is also
# possible to enable an authentication check for methods of the service.
# @attr [MarilynRPC::ServiceCache] service_cache the service cache where an 
#   instance lives in
# @example a service that makes use of the available helpers
#   class EventsService < MarilynRPC::Service
#     register :events
#     after_connect :connected
#     after_disconnect :disconnected
#     authentication_required :notify
#   
#     def connected
#       puts "client connected"
#     end
#   
#     def notify(msg)
#       puts msg
#     end
#   
#     def disconnected
#       puts "client disconnected"
#     end
#   end
#
class MarilynRPC::Service < ServiceBlankSlate
  attr_accessor :service_cache
  
  # registers the class where is was called as a service
  # @param [String] path the path of the service
  def self.register(path)
    @@registry ||= {}
    @@registry[path] = self
  end
  
  # returns all services, that where registered
  # @api private
  # @return [Hash<String, Object>] all registered services with path as key and
  #   the registered service as object
  def self.__registry__
    @@registry || {}
  end
  
  # register one or more connect callbacks, a callback is simply a method
  # defined in the class
  # @param [Array<Symbol>, Array<String>] callbacks the method names
  def self.after_connect(*callbacks)
    __register_callbacks__ :after_connect, callbacks
  end
  
  # register one or more disconnect callbacks, a callback is simply a method
  # defined in the class
  # @param [Array<Symbol>, Array<String>] callbacks the method names
  def self.after_disconnect(*callbacks)
    __register_callbacks__ :after_disconnect, callbacks
  end
  
  # registers a callbacks for the service class
  # @param [Symbol] name the name under which the callbacks should be saved
  # @param [Array<Symbol>, Array<String>] callbacks the method names
  # @api private
  def self.__register_callbacks__(name, callbacks)
    @_callbacks ||= {}         # initialize callbacks
    @_callbacks[name] ||= []   # initialize specific set
    @_callbacks[name] += callbacks
  end
  
  # returns the registered callbacks for name
  # @param [Symbol] name the name to lookup callbacks for
  # @return [Array<String>, Array<Symbol>] an array of callback names, or an
  #   empty array
  # @api private
  def self.__registered_callbacks__(name)
    @_callbacks ||= {}
    @_callbacks[name] || []
  end
  
  # this generator marks the passed method names to require authentication.
  # A Method that requires authentication is only callable if the client was
  # successfully authenticated.
  # @param [Array<String>, Array<Symbol>] methods the methods names
  def self.authentication_required(*methods)
    @_authenticated ||= {} # initalize hash of authenticated methods
    methods.each { |m| @_authenticated[m.to_sym] = true }
  end
  
  # returns all methods of the service that require authentication
  # @return [Array<Symbol>] methods that require authentication
  # @api private
  def self.__methods_with_authentication__
    @_authenticated ||= {}
  end
  
  # calls the defined connect callbacks
  # @param [Symbol] the name of the callbacks to run
  # @api private
  def __run_callbacks__(name)
    self.class.__registered_callbacks__(name).each do |callback|
      self.__send__(callback)
    end
  end
  
  # returns the username if a user is authenticated
  # @return [String, nil] the username or nil, if no user is authenticated
  def session_username
    @service_cache.username
  end
  
  # checks if a user is authenticated
  # @return [Boolean] `true` if a user is authenticated, `false` otherwise
  def session_authenticated?
    !@service_cache.username.nil?
  end
  
  # the name for the service which will be used to do the authentication
  AUTHENTICATION_PATH = :__marilyn_rpc_service_authentication
  
  # define an authentication mechanism using a `lambda` or `Proc` object, or
  # something else that respond to `call`. The authentication is available for
  # all serivces of that connection.
  # @param [Proc] &authenticator the authentication mechanism
  # @yieldparam [String] username the username of the client
  # @yieldparam [String] password the password of the client
  # @yieldreturn [Boolean] To authenticate a user, the passed
  #   block must return `true` otherwise `false`
  # @example Create a new authentication mechanism for clients using callable
  #   MarilynRPC::Service.authenticate_with do |username, password|
  #     username == "testuserid" && password == "secret"
  #   end
  # 
  def self.authenticate_with(&authenticator)
    Class.new(self) do # anonymous class
      @@authenticator = authenticator
      register(AUTHENTICATION_PATH)
      
      # authenticate the user using a plain password method
      # @param [String] username the username of the client
      # @param [String] password the password of the client
      def authenticate_plain(username, password)
        if @@authenticator.call(username, password)
          @service_cache.username = username
        else
          raise MarilynRPC::PermissionDeniedError.new \
            "Wrong username or password!"
        end
      end
    end
  end
end
