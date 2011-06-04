class MarilynRPC::Service
  # registers the class where is was called as a service
  # @param [String] path the path of the service
  def self.register(path)
    @@registry ||= {}
    @@registry[path] = self
  end
  
  # returns all services, that where registered
  # @return [Hash<String, Object>] all registered services with path as key and
  #   the registered service as object
  def self.registry
    @@registry || {}
  end
end
