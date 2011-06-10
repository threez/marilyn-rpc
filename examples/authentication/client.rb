$:.push(File.join(File.dirname(__FILE__), "..", "..", "lib"))
require "marilyn-rpc"
client = MarilynRPC::NativeClient.connect_tcp('localhost', 8000)
TestService = client.for(:test)

begin
  p TestService.add(1, 2)
rescue MarilynRPC::MarilynError => ex
  puts "PermissionDenied: #{ex.message}"
end

p TestService.time.to_f

client.authenticate "testuserid", "secret"

p TestService.add(1, 2)

client.disconnect
