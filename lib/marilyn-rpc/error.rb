module MarilynRPC
  class MarilynError < StandardError; end
  
  # Error that occurs, when we recieve an broken envelope
  class BrokenEnvelopeError < MarilynError; end
  
  # Error that occurs, when the client tries to call an unknown service
  class UnknownServiceError < MarilynError; end

  # Error that occurs, when the client tries to call an service, that requires
  # authentication. The client must be authenticated before that call.
  class PermissionDeniedError < MarilynError; end
end
