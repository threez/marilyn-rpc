$:.push(File.join(File.dirname(__FILE__), "..", "lib"))
require "marilyn-rpc"

def envelope_call(tag, path, method, *args)
  e = MarilynRPC::Envelope.new
  e.parse!(MarilynRPC::MailFactory.build_call(tag, path, method, args))
  e
end

def unpack_envelope(data)
  envelope = MarilynRPC::Envelope.new
  envelope.parse!(data)
  MarilynRPC::MailFactory.unpack(envelope)
end
