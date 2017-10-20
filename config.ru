require 'rack'
# require 'rack/json_parser'
require_relative 'lib/rack/json_parser'

COMMON_HEADERS = { 'CONTENT_TYPE' => 'application/json' }.freeze

# handler helper to build a response
# taking an object as the body which is transformed by JSONParser middleware
def respond(status, body = {}, headers = {})
  headers = COMMON_HEADERS.merge(headers)
  [status, headers, body]
end

# example rack app for testing middleware
def app
  healthcheck = proc { [204, {}, []] }
  hello = proc { respond 200, 'message' => 'Bout ye!' }
  greet = proc do |env|
    req = env['payload']
    full_name = req['forenames'].push(req['surname']).join(' ')
    respond 200, 'full_name' => full_name
  end

  Rack::Builder.new do
    use Rack::Lint
    use Rack::JSONParser

    map('/healthcheck') { run healthcheck }
    map('/hello') { run hello }
    map('/greet') { run greet }
  end
end

run app