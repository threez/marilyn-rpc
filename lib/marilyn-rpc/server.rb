module MarilynRPC::Server
  # Initialize the first recieving envelope for the connection and create the
  # service cache since each connection gets it's own service instance.
  def post_init
    @envelope = MarilynRPC::Envelope.new
    @cache = MarilynRPC::ServiceCache.new
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
    @cache.call_after_disconnect_callbacks!
  end
end
