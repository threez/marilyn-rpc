$:.push('../lib')
require "marilyn-rpc"
client1 = MarilynRPC::NativeClient.connect_tcp('localhost', 8483)
TestService1 = client1.for(:test)
client2 = MarilynRPC::NativeClient.connect_unix("tmp.socket")
TestService2 = client2.for(:test)

require "benchmark"
n = 10000
Benchmark.bm(10) do |b|
  b.report("tcp add") do 
    n.times { TestService1.add(1, 2) }
  end
  b.report("tcp time") do
    n.times { TestService1.time.to_f }
  end
  b.report("unix add") do 
    n.times { TestService2.add(1, 2) }
  end
  b.report("unix time") do
    n.times { TestService2.time.to_f }
  end
end

client1.disconnect
client2.disconnect