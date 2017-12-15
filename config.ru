require 'rack'
# require 'rack/json_parser'
require_relative 'lib/rack/json_parser'

JSON_CONTENT_TYPE = { 'Content-Type' => 'application/json' }.freeze

# Example rack app for testing middleware.
def app
  healthcheck = proc { [204, {}, []] }

  hello = proc { [200, {}, 'message' => 'Bout ye!'] }

  greet = proc do |env|
    req = env['request.payload']
    if req
      full_name = req['forenames'].push(req['surname']).join(' ')
      [200, {}, 'full_name' => full_name]
    else
      [400, {}, []]
    end
  end

  string = proc do |env|
    [200, {}, '{ "name": "Michael" }']
  end

  dict = proc do |env|
    [200, {}, { name: "Harold" }]
  end

  obj = proc do |env|
    obj = OpenStruct.new(name: 'Michael', pets: %w[Harold Molly]).freeze
    [200, {}, obj]
  end

  Rack::Builder.new do
    use Rack::Lint
    use Rack::JSONParser

    map('/healthcheck') { run healthcheck }
    map('/hello') { run hello }
    map('/greet') { run greet }
    map('/string') { run string }
    map('/dict') { run dict }
    map('/obj') { run obj }
  end
end

run app
