lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name        = 'simple_tracing'
  s.version     = '0.2.0'

  s.date        = '2015-01-26'
  s.summary     = "Simple Tracing and Instrumentation for ruby"
  s.description = "A way of tracing your apps' network calls and slow code."
  s.authors     = ["Aaron Blohowiak"]
  s.email       = 'aaron.blohowiak@gmail.com'
  s.files       = `git ls-files`.split($\)
  s.homepage    = 'http://github.com/fanhattan/simple-tracing'
  s.require_paths = ["lib"]

  s.license       = 'MIT'
  s.add_dependency "absolute_time"
end
