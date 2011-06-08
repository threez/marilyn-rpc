$:.push(File.join(File.dirname(__FILE__), "..", "..", "lib"))
require "marilyn-rpc"
client = MarilynRPC::NativeClient.connect_tcp('localhost', 8483)
EventsService = client.for(:events)

EventsService.notify("Hello World")

client.disconnect
