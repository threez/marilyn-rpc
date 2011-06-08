$:.push(File.join(File.dirname(__FILE__), "..", "..", "lib"))
require "marilyn-rpc"
require "rubygems"
require "eventmachine"

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

EM.run {
  EM.start_server "localhost", 8483, MarilynRPC::Server
}
