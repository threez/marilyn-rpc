require 'socket'

module MarilynRPC
  class NativeClientProxy
    # Creates a new Native client proxy, were the calls get send to the remote
    # side.
    # @param [Object] path the path that is used to identify the service
    # @param [Socekt] socket the socket to use for communication
    def initialize(path, socket)
      @path, @socket = path, socket
    end

    # Handler for calls to the remote system
    def method_missing(method, *args, &block)
      # since this client can't multiplex, we set the tag to nil
      @socket.write(MarilynRPC::MailFactory.build_call(nil, @path, method, args))

      # read the answer of the server back in
      answer = MarilynRPC::Envelope.new
      # read the header to have the size
      answer.parse!(@socket.read(4))
      # so now that we know the site, read the rest of the envelope
      answer.parse!(@socket.read(answer.size))

      # returns the result part of the mail or raise the exception if there is 
      # one
      mail = MarilynRPC::MailFactory.unpack(answer)
      if mail.is_a? MarilynRPC::CallResponseMail
        mail.result
      else
        raise mail.exception
      end
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
    # Create a native client for the socket.
    # @param [Socket] socket the socket to manage
    def initialize(socket)
      @socket = socket
    end

    # Disconnect the client from the remote.
    def disconnect
      @socket.close
    end

    # Creates a new Proxy Object for the connection.
    # @param [Object] path the path were the service is registered on the remote
    #   site
    # @return [MarilynRPC::NativeClientProxy] the proxy obejct that will serve
    #   all calls
    def for(path)
      NativeClientProxy.new(path, @socket)
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
    # @return [MarilynRPC::NativeClient] the cónnected client
    def self.connect_tcp(host, port)
      new(TCPSocket.open(host, port))
    end
  end
end
