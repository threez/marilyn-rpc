# The gentleman is a proxy onject that should help to create async responses on 
# the server (service) side. There are two ways to use the gentleman. See the
# examples.
# 
# @example Use the gentleman als passed block
#   MarilynRPC::Gentleman.proxy do |helper|
#     EM.system('ls', &helper)
#   
#     lambda do |output,status|
#       output if status.exitstatus == 0 
#     end
#   end
#
# @example Use the gentleman for responses that are objects
#   conn = EM::Protocols::HttpClient2.connect 'google.com', 80
#   req = conn.get('/')
#   MarilynRPC::Gentleman.new(conn) do |response|
#     response.content
#   end
#
# The Gentleman has to be returned by the service method.
#
# @attr [Object] connection the connection where the response should be send
# @attr [Proc] callback the callback that will be called when the deferable 
#   was successful
# @attr [Object] tag the tag that should be used for the response
class MarilynRPC::Gentleman
  attr_accessor :connection, :callback, :tag
  
  # create a new proxy object using a deferable or the passed block.
  # @param [EventMachine::Deferrable] deferable
  def initialize(deferable = nil, &callback)
    @callback = callback
    if deferable
      unless deferable.respond_to? :callback
        raise ArgumentError.new("Wrong type, expected object that responds to #callback!")
      end
      gentleman = self
      deferable.callback { |*args| gentleman.handle(*args) }
    end
  end
  
  # Creates a anonymous Gentleman proxy where the helper is exposed to, be able
  # to use the Gentleman in situations where only a callback can be passed.
  def self.proxy(&block)
    gentleman = MarilynRPC::Gentleman.new
    gentleman.callback = block.call(gentleman.helper)
    gentleman
  end
  
  # The handler that will send the response to the remote system
  # @param [Object] args the arguments that should be handled by the callback,
  #   the reponse of the callback will be send as result
  # @api private
  def handle(*args)
    mail = MarilynRPC::CallResponseMail.new(self.tag, self.callback.call(*args))
    data = MarilynRPC::Envelope.new(mail.encode, 
                                    MarilynRPC::CallResponseMail::TYPE).encode
    connection.send_data(data)
  rescue Exception => exception
    mail = MarilynRPC::ExceptionMail.new(self.tag, exception)
    data = MarilynRPC::Envelope.new(mail.encode,
                                    MarilynRPC::ExceptionMail::TYPE).encode
    connection.send_data(data)
  end
  
  # The helper that will be called by the deferable to call 
  # {MarilynRPC::Gentleman#handle} later
  # @api private
  def helper
    gentleman = self
    lambda { |*args| gentleman.handle(*args) }
  end
end
