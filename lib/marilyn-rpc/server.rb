# The server will be used to make incomming connections possible. The server
# handles the low level networking functions, so that the services don't have
# to deal with them. Because of the way eventmachine works you can have as many
# servers as you want.
#
# @example a server which is available througth 3 connections:
#   EM.run {
#     EM.start_server "localhost", 8000, MarilynRPC::Server
#     EM.start_server "localhost", 8008, MarilynRPC::Server, :secure => true
#     EM.start_unix_domain_server("tmp.socket", MarilynRPC::Server)
#   }
#
module MarilynRPC::Server
  # initalize the server with connection options
  # @param [Hash] options the options passed to the server
  # @option options [Boolean] :secure enable secure transfer for the server
  #   possible values `true` or `false`
  def initialize(options = {})
    @secure = options[:secure]
  end
  
  # Initialize the first recieving envelope for the connection and create the
  # service cache since each connection gets it's own service instance.
  def post_init
    @envelope = MarilynRPC::Envelope.new
    @cache = MarilynRPC::ServiceCache.new
    start_tls if @secure
  end
  
  # Handler for the incoming data. EventMachine compatible.
  # @param [String] data the data that should be parsed into envelopes
  def receive_data(data)
    overhang = @envelope.parse!(data)
    
    # was massage parsed successfully?
    if @envelope.finished?
      begin
        # grep the request
        answer = @cache.call(MarilynRPC::MailFactory.unpack(@envelope))
        if answer.is_a? MarilynRPC::CallResponseMail
          send_mail(answer)
        else
          answer.connection = self # pass connection for async responses
        end
      rescue => exception
        send_mail(MarilynRPC::ExceptionMail.new(exception))
      end
      
      # initialize the next envelope
      @envelope = MarilynRPC::Envelope.new
      receive_data(overhang) if overhang # reenter the data loop
    end
  end
  
  # Send a response mail back on the wire of buffer
  # @param [MarilynRPC::ExceptionMail, MarilynRPC::CallResponseMail] mail the 
  #   mail that should be send to the client
  def send_mail(mail)
    send_data(MarilynRPC::Envelope.new(mail.encode).encode)
  end
  
  # Handler for client disconnect
  def unbind
    @cache.disconnect!
  end
end
