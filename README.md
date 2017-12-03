# Rack::JSONParser Middleware

Rack middleware which transforms an incoming request's JSON string into a `Hash` and any outgoing ruby `Object` back into a JSON string to be returned to the client.

- The client sends/receives only JSON strings
- The `app` (rack application) using the middleware sends/receives only ruby objects (no JSON parsing)
- The `Rack::JSONParser` middleware handles the parsing of the request/response to/from JSON/Object so you don't have to

The difference between this and other middleware doing the same job is that it's fast! This middleware uses the '[oj](https://github.com/ohler55/oj)' gem which gives faster processing than the `json` gem. This middleware is also configurable enabling predictive and controlled parsing. It stays out of your way when you don't need it and is seamless when you do.

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'rack-jsonparser'
```

And then execute:

    $ bundle

Or install it yourself with:

    $ gem install rack-jsonparser

Then `require` it in your rack application with:

```ruby
require 'rack/json_parser'
```

## Usage

Below is a sample rack app which uses the middleware to send and receive JSON:

> config.ru

```ruby
require 'rack/json_parser'

# Notice how the `payload` is a Hash, not a JSON string
# We return a Hash instance (or any Ruby object) for the response body
# We can turn off the request/response parsing via the `use` method (defaults to true)
# Parsing will only occur if enabled AND the Content-Type is `application/json`
handler = proc do |env|
  payload = env['payload']
  full_name = payload['forenames'].push(payload['surname']).join(' ')
  res_hash = { 'full_name' => full_name }
  [200, { 'Content-Type' => 'application/json' }, res_hash]
end

app = Rack::Builder.new do
  use Rack::JSONParser, transform_request: true, transform_response: true
  map('/hello') { run handler }
end

run app
```

Run the above `config.ru` rack app with:

    $ rackup

Then query the app with:

```shell
curl -X POST \
  http://localhost:9292/hello \
  -H 'content-type: application/json' \
  -d '{
	"forenames": [
		"Napolean",
		"Neech"
	],
	"surname":"Manly"
  }'
```

And the JSON response will be:

```json
{
  "full_name":"Napolean Neech Manly"
}
```

## Configuration

The middleware is configurable so request/response processing can be turned off via the `use` method parameters if desired, see usage above.

In addition, the middleware only transforms the request/response if the `Content-Type` header is correctly set to `application/json`. This applies to both the request sent from the client and the response sent from the `app`; allowing for several types of response content to be served by the application without interference by the middleware. This however requires the client and rack `app` to set the `Content-Type` header correctly. If not, then the middleware will do nothing and simply pass through the request/response data which might lead to unexpected behavior.

If the middleware processes the response then it will also set/override the `Content-Length` header with the length of the JSON string being returned to the client.

## Ruby Version

This software was built with and supports:

- `~> 2.4.0`

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/michaeltelford/rack_jsonparser).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
