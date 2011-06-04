# -*- encoding: utf-8 -*-
$:.push('lib')
require "marilyn-rpc/version"

Gem::Specification.new do |s|
  s.name     = "marilyn-rpc"
  s.version  = MarilynRPC::VERSION.dup
  s.date     = "2011-06-04"
  s.summary  = "Simple, beautiful event-based RPC"
  s.email    = "vilandgr+github@googlemail.com"
  s.homepage = "https://github.com/threez/marilyn-rpc"
  s.authors  = ['Vincent Landgraf']
  
  s.description = <<-EOF
A simple, beautiful event-based (EventMachine) RPC service and client library
EOF
  
  dependencies = [
    [:runtime,     "eventmachine",  "~> 0.12.10"],
    [:development, "rspec",         "~> 2.4"],
  ]
  
  s.files         = Dir['**/*']
  s.test_files    = Dir['test/**/*'] + Dir['spec/**/*']
  s.executables   = Dir['bin/*'].map { |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  
  ## Make sure you can build the gem on older versions of RubyGems too:
  s.rubygems_version = "1.3.7"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.specification_version = 3 if s.respond_to? :specification_version
  
  dependencies.each do |type, name, version|
    if s.respond_to?("add_#{type}_dependency")
      s.send("add_#{type}_dependency", name, version)
    else
      s.add_dependency(name, version)
    end
  end
end
