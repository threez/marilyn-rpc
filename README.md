![alt text](kiss.png "MarilynRPC")

# MarilynRPC

Marilyn is a simple, elegant rpc service and client infrastructure that has
learned some lessons on how we organize our code in typical web projects like
rails. It's purpose is to call multiple services over a persistent connection.
The services are unique per connection, so if you have 50 connections, 50 
service objects will be used, if (and only if) they are requested by the client.

Since this is a session dedicated to one connection, marilyn has support for per 
connection caching by using instance variables. Further on, it is planned to 
enhance the capabilities of marilyn to allow connection based authentication.
Like in other protocols (e.g. IMAP) where come method can be called
unauthenticated and some not. We plan to enable TLS to have a secure connection.
Like in IMAP marilyn supports sending of multiple requests to a server over one
connection. This feature is not supported by the current client implementation,
but things will get changed in the feature.

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
    
## Async Server Example

As previously said, the server can use the `Gentleman` to issue asynchronous
responses:

    TODO ...

The asynchronous server is transparent to the client. The client, doen't even
know, that his request is processed asynchronously.

## License / Author

Copyright (c) 2011 Vincent Landgraf
All Rights Reserved. Released under a [MIT License](LICENCE).
