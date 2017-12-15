require 'oj'
require 'rack'

module Rack
  # Rack middleware which transforms JSON during the request and response.
  # Configurable so request/response processing can be turned off if desired.
  # Only transforms if the Content-Type header is set and includes
  # 'application/json'. This allows for several types of response content to be
  # served by the application without interference by this middleware. This
  # however requires the client and app to set the 'Content-Type' correctly.
  class JSONParser
    CONTENT_TYPE_KEY     = 'Content-Type'.freeze
    CONTENT_TYPE_ALT_KEY = 'CONTENT_TYPE'.freeze
    CONTENT_LENGTH_KEY   = 'Content-Length'.freeze

    CONTENT_TYPE_JSON    = 'application/json'.freeze

    ENV_PAYLOAD_KEY      = 'request.payload'.freeze
    ENV_RACK_INPUT_KEY   = 'rack.input'.freeze

    # Called via the rack `use` method. Used to register the middleware and
    # optionally toggle request and response processing of JSON to Object.
    # By default both the request and response is processed and transformed.
    def initialize(app, transform_request: true, transform_response: true)
      @app = app
      @transform_request = transform_request
      @transform_response = transform_response
    end

    # Loads the request JSON string into a Hash instance.
    # Expects the app response body to be an object e.g. Hash,
    # putting the object in an array will likely cause unexpected JSON.
    # If the response body is processed then the `Content-Length` header will
    # be set to the body#length.
    def call(env)
      env = Rack::Utils::HeaderHash.new(env)

      if transform_request?(env)
        env[ENV_PAYLOAD_KEY] = Oj.load(env[ENV_RACK_INPUT_KEY])
      end

      status, headers, body = @app.call(env)
      headers = Rack::Utils::HeaderHash.new(headers)

      if transform_response?(headers, body)
        body = Oj.dump(body) unless body.is_a?(String)
        headers[CONTENT_LENGTH_KEY] = body.length.to_s
        body = [body] unless body.respond_to?(:each)
      end

      [status, headers, body]
    end

  private

    # Determine whether or not to transform the JSON request from the client
    # into an Object. Takes into account the `@transform_request` variable and
    # request parameters such as headers and request body.
    def transform_request?(env)
      @transform_request &&
        json_content_type?(env) &&
        env[ENV_RACK_INPUT_KEY] &&
        true # so the return value is true if all prior conditions are true
    end

    # Determine whether or not to transform the JSON response from the app
    # into a JSON string. Takes into account the `@transform_response` variable
    # and response parameters such as headers and response body.
    def transform_response?(headers, body)
      @transform_response &&
        json_content_type?(headers) &&
        body &&
        true # so the return value is true if all prior conditions are true
    end

    # Determine whether or not the 'Content-Type' is 'application/json'.
    # The content type value assertion is always case insensitive and supports
    # both a dash/hyphen and an underscore. The content type key assertion
    # depends on the env parameter. A Hash is case sensitive by default whereas
    # a Rack::Utils::HeaderHash is case insensitive.
    def json_content_type?(env)
      if env.include?(CONTENT_TYPE_KEY)
        env[CONTENT_TYPE_KEY].downcase == CONTENT_TYPE_JSON.downcase
      elsif env.include?(CONTENT_TYPE_ALT_KEY)
        env[CONTENT_TYPE_ALT_KEY].downcase == CONTENT_TYPE_JSON.downcase
      else
        false
      end
    end
  end
end
