%w(error version gentleman envelope mails service 
   server service_cache client).each do |file|
  require File.join(File.dirname(__FILE__), "marilyn-rpc", file)
end
