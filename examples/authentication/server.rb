$:.push(File.join(File.dirname(__FILE__), "..", "..", "lib"))
require "marilyn-rpc"
require "rubygems"
require "eventmachine"

MarilynRPC::Service.authenticate_with do |username, password|
  username == "testuserid" && password == "secret"
end

class TestService < MarilynRPC::Service
  register :test
  authentication_required :add
  
  def time
    puts session_username
    puts session_authenticated?
    Time.now
  end
  
  def add(a, b)
    puts session_username
    puts session_authenticated?
    a + b
  end
end


EM.run {
  EM.start_server "localhost", 8000, MarilynRPC::Server
}
