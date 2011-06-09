$:.push(File.join(File.dirname(__FILE__), "..", "..", "lib"))
require "marilyn-rpc"
client = MarilynRPC::NativeClient.connect_tcp('localhost', 8000)
SimpleCommandService = client.for(:cmd)

start_time = Time.now

t1 = Thread.new do
  SimpleCommandService.exec("sleep 5")
  puts "ls -al\n: " + SimpleCommandService.exec("ls -al")
end

t2 = Thread.new do
  SimpleCommandService.exec("sleep 2")
  puts "uname -a\n: " + SimpleCommandService.exec("uname -a")
end

done = false
t3 = Thread.new do
  while !done
    sleep 1
    STDOUT.print "."
    STDOUT.flush
  end
end

t1.join
t2.join

done = true
end_time = Time.now

puts "#{start_time - end_time}"

client.disconnect
