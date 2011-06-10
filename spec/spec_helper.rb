$:.push(File.join(File.dirname(__FILE__), "..", "lib"))
require "marilyn-rpc"

def envelope_call(tag, path, method, *args)
  mail = MarilynRPC::CallRequestMail.new(tag, path, method, args)
  MarilynRPC::Envelope.new(mail.encode)
end
