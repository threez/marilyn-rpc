require 'socket'
require 'thread'

module MarilynRPC
  # A class with nothing but `__send__` and `__id__`
  class ClientBlankSlate
    instance_methods.each { |m| undef_method m unless m =~ /^__|object_id/ }
  end
  
  class NativeClientProxy < ClientBlankSlate
    # Creates a new Native client proxy, were the calls get send to the remote
    # side.
    # @param [Object] path the path that is used to identify the service
    # @param [NativeClient] client the client to use for communication
    def initialize(path, client)
      @path, @client = path, client
    end

    # Handler for calls to the remote system
    def method_missing(method, *args, &block)
      @client.execute(@path, method, args)
    end
  end

  # The client that will handle the socket to the remote. The native client is
  # written in pure ruby.
  # @example Using the native client
  #   require "marilyn-rpc"
  #   client = MarilynRPC::NativeClient.connect_tcp('localhost', 8483)
  #   TestService = client.for(:test)
  #   TestService.add(1, 2)
  #   TestService.time.to_f
  #
  class NativeClient
    MAIL_KEY = :_mlynml
    
    # Create a native client for the socket.
    # @param [Socket] socket the socket to manage
    def initialize(socket)
      @socket = socket
      @semaphore = Mutex.new
      @threads = {}
      @thread = Thread.new do
        # read the answer of the server back in
        envelope = MarilynRPC::Envelope.new
        loop do
          # read the header to have the size
          envelope.parse_header! @socket.read(MarilynRPC::Envelope::HEADER_SIZE)
          # so now that we know the site, read the rest of the envelope without
          # parsing
          envelope.content = @socket.read(envelope.size)

          # returns the result part of the mail or raise the exception if there is 
          # one
          mail = MarilynRPC::MailFactory.unpack(envelope)
          thread = @semaphore.synchronize { @threads.delete(mail.tag) }
          thread[MAIL_KEY] = mail # save the mail for the waiting thread
          thread.wakeup # wake up the waiting thread
          envelope.reset!
        end
      end
    end

    # Disconnect the client from the remote.
    def disconnect
      @socket.close
    end
    
    # authenicate the client to call methods that require authentication
    # @param [String] username the username of the client
    # @param [String] password the password of the client
    # @param [Symbol] method the method to use for authentication, currently
    #   only plain is supported. So make sure you are using a secure socket.
    def authenticate(username, password, method = :plain)
      execute(MarilynRPC::Service::AUTHENTICATION_PATH,
              "authenticate_#{method}".to_sym, [username, password])
    end

    # Creates a new Proxy Object for the connection.
    # @param [Object] path the path were the service is registered on the remote
    #   site
    # @return [MarilynRPC::NativeClientProxy] the proxy obejct that will serve
    #   all calls
    def for(path)
      NativeClientProxy.new(path, self)
    end
    
    # Connect to a unix domain socket.
    # @param [String] path the path to the socket file.
    # @return [MarilynRPC::NativeClient] the cónnected client
    def self.connect_unix(path)
      new(UNIXSocket.new(path))
    end
    
    # Connect to a tcp socket.
    # @param [String] host the host to cennect to (e.g. 'localhost')
    # @param [Integer] port the port to connect to (e.g. 8000)
    # @param [Hash] options the
    # @option options [Boolean] :secure use tls/ssl for the connection
    #   `true` or `false`
    # @option options [OpenSSL::SSL::SSLContext] :ssl_context can be used to
    #   change the ssl context of the newly created secure connection. Only
    #   takes effect if `:secure` option is enabled.
    # @return [MarilynRPC::NativeClient] the connected client
    def self.connect_tcp(host, port, options = {})
      if options[:secure] == true
        require 'openssl' # use openssl for secure connections
        socket = TCPSocket.new(host, port)
        if ssl_context = options[:ssl_context]
          secure_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
        else
          secure_socket = OpenSSL::SSL::SSLSocket.new(socket)
        end
        secure_socket.connect
        new(secure_socket)
      else
        new(TCPSocket.open(host, port))
      end
    end
    
    # Executes a client call blocking. To issue an async call one needs to
    # have start separate threads. THe Native client uses then multiplexing to
    # avoid the other threads blocking.
    # @api private
    # @param [Object] path the path to identifiy the service
    # @param [Symbol, String] method the method name to call on the service
    # @param [Array<Object>] args the arguments that are passed to the remote
    #   side
    # @return [Object] the result of the call
    def execute(path, method, args)
      thread = Thread.current
      tag = "#{Time.now.to_f}:#{thread.object_id}"
      
      @semaphore.synchronize {
        # since this client can't multiplex, we set the tag to nil
        @socket.write(MarilynRPC::MailFactory.build_call(tag, path, method, args))
      }
      
      # lets write our self to the list of waining threads
      @semaphore.synchronize { @threads[tag] = thread }
      
      # stop the current thread, the thread will be started after the response
      # arrived
      Thread.stop

      # get mail from responses
      mail = thread[MAIL_KEY]

      if mail.is_a? MarilynRPC::CallResponseMail
        mail.result
      else
        raise MarilynError.new # raise exception to capture the client backtrace
      end
    rescue MarilynError => exception
      # add local and remote trace together and reraise the original exception
      backtrace = []
      backtrace += exception.backtrace
      backtrace += mail.exception.backtrace
      mail.exception.set_backtrace(backtrace)
      raise mail.exception
    end
  end
end
