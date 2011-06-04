require "rubygems"
$:.push('../lib')
require "marilyn-rpc"
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
  EM.start_server "localhost", 8483, MarilynRPC::Server
  EM.start_unix_domain_server("tmp.socket", MarilynRPC::Server)
}
