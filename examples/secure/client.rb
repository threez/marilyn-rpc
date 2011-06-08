$:.push(File.join(File.dirname(__FILE__), "..", "..", "lib"))
require "marilyn-rpc"
client = MarilynRPC::NativeClient.connect_tcp('localhost', 8008, :secure => true)
TestService = client.for(:test)

p TestService.add(1, 2)
p TestService.time.to_f

client.disconnect
