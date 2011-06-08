$:.push(File.join(File.dirname(__FILE__), "..", "..", "lib"))
require "marilyn-rpc"
require "rubygems"
require "eventmachine"

class TestService < MarilynRPC::Service
  register :test
  
  def time
    Time.now
  end
  
  def add(a, b)
    a + b
  end
end


EM.run {
  EM.start_server "localhost", 8000, MarilynRPC::Server
  EM.start_server "localhost", 8008, MarilynRPC::Server, :secure => true
}
