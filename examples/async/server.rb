$:.push(File.join(File.dirname(__FILE__), "..", "..", "lib"))
require "marilyn-rpc"
require "rubygems"
require "eventmachine"

class SimpleCommandService < MarilynRPC::Service
  register :cmd
  
  def exec(line)
    MarilynRPC::Gentleman.proxy do |helper|
      EM.system(line, &helper)
    
      lambda do |output,status|
        if (code = status.exitstatus) == 0
          output 
        else
          code
        end
      end
    end
  end
end

EM.run {
  EM.start_server "localhost", 8000, MarilynRPC::Server
}
