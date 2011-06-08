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
  
  # register one or more connect callbacks
  # @param [Array<Symbol>, Array<String>] callbacks
  def self.after_connect(*callbacks)
    @@_after_connect_callbacks ||= []
    @@_after_connect_callbacks += callbacks
  end
  
  # register one or more disconnect callbacks
  # @param [Array<Symbol>, Array<String>] callbacks
  def self.after_disconnect(*callbacks)
    @@_after_disconnect_callbacks ||= []
    @@_after_disconnect_callbacks += callbacks
  end
  
  # calls the defined connect callbacks
  # @api private
  def execute_after_connect_callback!
    (@@_after_connect_callbacks || []).each do |callback|
      self.send(callback)
    end
  end
  
  # calls the defined diconnect callbacks
  # @api private
  def execute_after_disconnect_callback!
    (@@_after_disconnect_callbacks || []).each do |callback|
      self.send(callback)
    end
  end
end
