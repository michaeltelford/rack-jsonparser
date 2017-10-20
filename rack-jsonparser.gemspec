Gem::Specification.new do |s|
  s.name          = 'rack-jsonparser'
  s.version       = '0.1.0'
  s.platform      = Gem::Platform::RUBY
  s.licenses      = ['MIT']
  s.authors       = ['Michael Telford']
  s.email         = ['michael.telford@live.com']
  s.homepage      = 'https://github.com/michaeltelford/rack-jsonparser'
  s.summary       = %q{Rack middleware for processing JSON requests and responses.}
  s.description   = %q{Rack middleware for processing JSON requests and responses using the 'oj' gem.}
  s.files         = Dir['lib/**/*.rb']
  s.require_paths = ['lib']
end