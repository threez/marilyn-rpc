$:.push('../lib')
require "marilyn-rpc"
client1 = MarilynRPC::NativeClient.connect_tcp('localhost', 8483)
TestService1 = client1.for(:test)
client2 = MarilynRPC::NativeClient.connect_unix("tmp.socket")
TestService2 = client2.for(:test)

if ARGV.size > 0
  require "benchmark"
  n = 5000
  
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
else
  require "rubygems"
  require "ruby-prof"
  require "benchmark"
  n = 500

  result = RubyProf.profile do
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
  end

  # Print a graph profile to text
  printer = RubyProf::GraphHtmlPrinter.new(result)
    printer.print(File.open("test.html", "w"), :min_percent=>0)
end
client1.disconnect
client2.disconnect