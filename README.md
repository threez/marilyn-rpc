![alt text](https://raw.github.com/threez/marilyn-rpc/master/kiss.png "MarilynRPC")

# MarilynRPC

Marilyn is a simple, elegant rpc service and client infrastructure that has
learned some lessons on how we organize our code in typical web projects like
rails. It's purpose is to call multiple services over a persistent connection.
The services are unique per connection, so if you have 50 connections, 50 
service objects will be used, if (and only if) they are requested by the client.

Since this is a session dedicated to one connection, marilyn has support for per 
connection caching by using instance variables. Further on, it is planned to 
enhance the capabilities of marilyn to allow connection based authentication.
Like in other protocols (e.g. IMAP) where some methods can be called
unauthenticated and some not.

Like in IMAP marilyn supports sending of multiple requests to a server over one
connection. This feature is called multiplexing supported by the current
`NativeClient` implementation.

The services rely on the eventmachine reactor. Marilyn supports asynchronous
responses based on the so called `Gentleman`. This class is a proxy object that
will handle the async responses for you.

Due to it's internals marilyn is very fast. On my local machine i can achieve
about 5000 (req + resp)/s.

Serialization of all data is done using ruby's build in `Marshal#dump` and `#load`. Since it was the fastest solution i found for typical scenarios.

It is especially designed for local connections too and therefore build to run
on both tcp and unix domain socket connections. Due to it's implementation in
operation systems is a unix domain socket typically faster than a tcp localhost
connection. I my tests up to 30 percent faster.

## Install

Easy and common using gems:

    gem install marilynrpc

## Server Example

This is a sample server that exposes 2 Services that can be easily exposed using
the eventmachine `start_server` function:

    require "marilyn-rpc"
    require "eventmachine"

    class CalcService < MarilynRPC::Service
      register :calc

      def add(a, b)
        a + b
      end
    end
    
    class TimeService < MarilynRPC::Service
      register :time
      
      def current
        Time.now
      end
    end

    EM.run {
      EM.start_server "localhost", 8483, MarilynRPC::Server
    }

## NativeClient Example (pure ruby)

The native client is a pure ruby implementation and dosn't require eventmachine
at all. Therefor it is very easy to use. However the downside is, that the
client is blocking for the call. But, since marilyn calls last only for
fractions of a millisecond (on a local connection) there should be no problem in
typical setups.

    require "marilyn-rpc"
    
    client = MarilynRPC::NativeClient.connect_tcp('localhost', 8483)
    CalcService = client.for(:calc)
    TimeService = client.for(:time)

    p CalcService.add(1, 2)
    p TimeService.current

    client.disconnect
    
## Service Events

Because a client has a dedicated service it is possible to add connect and
disconnect callbacks. These callbacks may help your application to
request/cache/optimize certain aspects of your service. Here is an example:

    class EventsService < MarilynRPC::Service
      register :events
      after_connect :connected
      after_disconnect :disconnected
  
      def connected
        puts "client connected"
      end
  
      def notify(msg)
        puts msg
      end
  
      def disconnected
        puts "client disconnected"
      end
    end

## Security

If you are using a tcp connection you can secure the connection using tls/ssl.
To enable it on the server side one has to pass the secure flag:

    EM.run {
      EM.start_server("localhost", 8008, MarilynRPC::Server, :secure => true)
    }

The client also simply has to enable a secure connection:

    client = MarilynRPC::NativeClient.connect_tcp('localhost', 8008, :secure => true)

## Async Server Example & NativeClient

As previously said, the server can use the `Gentleman` to issue asynchronous
responses:

    class SimpleCommandService < MarilynRPC::Service
      register :cmd

      def exec(line)
        MarilynRPC::Gentleman.proxy do |helper|
          EM.system(line, &helper)

          lambda do |output,status|
            if (code = status.exitstatus) == 0
              output 
            else
              code
            end
          end
        end
      end
    end

The asynchronous server is transparent to the client. The client, doen't even
know, that his request is processed asynchronously. If the client make use of
the multiplexing feature he can use multiple threads to do so:

    client = MarilynRPC::NativeClient.connect_tcp('localhost', 8000)
    SimpleCommandService = client.for(:cmd)

    start_time = Time.now

    Thread.new do
      SimpleCommandService.exec("sleep 5")
      puts "=== ls -al\n: " + SimpleCommandService.exec("ls -al")
    end

    Thread.new do
      SimpleCommandService.exec("sleep 2")
      puts "=== uname -a\n: " + SimpleCommandService.exec("uname -a")
    end

## License / Author

Copyright (c) 2011 Vincent Landgraf
All Rights Reserved. Released under a [MIT License](LICENCE).
