# This class represents the base for all events, it is used for registering
# services and defining callbacks for certain service events.
# @example a service that makes use of the available helpers
#   class EventsService < MarilynRPC::Service
#     register :events
#     after_connect :connected
#     after_disconnect :disconnected
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
class MarilynRPC::Service
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
  def self.registry
    @@registry || {}
  end
  
  # register one or more connect callbacks, a callback is simply a method
  # defined in the class
  # @param [Array<Symbol>, Array<String>] callbacks the method names
  def self.after_connect(*callbacks)
    register_callbacks :after_connect, callbacks
  end
  
  # register one or more disconnect callbacks, a callback is simply a method
  # defined in the class
  # @param [Array<Symbol>, Array<String>] callbacks the method names
  def self.after_disconnect(*callbacks)
    register_callbacks :after_disconnect, callbacks
  end
  
  # registers a callbacks for the service class
  # @param [Symbol] name the name under which the callbacks should be saved
  # @param [Array<Symbol>, Array<String>] callbacks the method names
  # @api private
  def self.register_callbacks(name, callbacks)
    @_callbacks ||= {}         # initialize callbacks
    @_callbacks[name] ||= []   # initialize specific set
    @_callbacks[name] += callbacks
  end
  
  # returns the registered callbacks for name
  # @param [Symbol] name the name to lookup callbacks for
  # @return [Array<String>, Array<Symbol>] an array of callback names, or an
  #   empty array
  # @api private
  def self.registered_callbacks(name)
    (@_callbacks || {})[name] || []
  end
  
  # calls the defined connect callbacks
  # @param [Symbol] the name of the callbacks to run
  # @api private
  def run_callbacks!(name)
    self.class.registered_callbacks(name).each do |callback|
      self.send(callback)
    end
  end
end
