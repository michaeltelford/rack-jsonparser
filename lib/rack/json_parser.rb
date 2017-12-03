require 'oj'

module Rack
  # Rack middleware which transforms JSON during the request and response.
  # Configurable so request/response processing can be turned off if desired.
  # Only transforms if the Content-Type header is set and includes
  # 'application/json'. This allows for several types of response content to be
  # served by the application without interference by this middleware. This
  # however requires the client and app to set the 'Content-Type' correctly.
  class JSONParser
    CONTENT_TYPE_KEY    = 'Content-Type'.freeze
    CONTENT_LENGTH_KEY  = 'Content-Length'.freeze

    CONTENT_TYPE_JSON   = 'application/json'.freeze

    ENV_PAYLOAD_KEY     = 'payload'.freeze
    ENV_RACK_INPUT_KEY  = 'rack.input'.freeze

    # Called via the rack `use` method. Used to register the middleware and
    # optionally toggle request and response processing of JSON to Object.
    # By default both the request and response is processed and transformed.
    def initialize(app, transform_request: true, transform_response: true)
      @app = app
      @transform_request = transform_request
      @transform_response = transform_response
    end

    # Loads the request JSON string into a Hash instance.
    # Expects the app response body to be an object instance e.g. Hash,
    # putting the object in an array will likely cause unexpected JSON.
    # If the response body is processed then the `Content-Length` header will
    # be set to the body#length.
    def call(env)
      if transform_request?(env)
        env[ENV_PAYLOAD_KEY] = Oj.load(env[ENV_RACK_INPUT_KEY])
      end

      status, headers, body = @app.call(env)

      if transform_response?(headers, body)
        body = Oj.dump(body)
        headers[CONTENT_LENGTH_KEY] = body.length.to_s
        body = [body] unless body.is_a?(Array)
      end

      [status, headers, body]
    end

  private

    # Determine whether or not to transform the JSON request from the client
    # into an Object. Takes into account the `@transform_request` variable and
    # request parameters such as headers and request body.
    def transform_request?(env)
      @transform_request &&
        env[CONTENT_TYPE_KEY] == CONTENT_TYPE_JSON &&
        env[ENV_RACK_INPUT_KEY] &&
        true # so the return value is true if all prior conditions are true
    end

    # Determine whether or not to transform the JSON response from the app
    # into a JSON string. Takes into account the `@transform_response` variable
    # and response parameters such as headers and response body.
    def transform_response?(headers, body)
      @transform_response &&
        headers[CONTENT_TYPE_KEY] == CONTENT_TYPE_JSON &&
        body &&
        true # so the return value is true if all prior conditions are true
    end
  end
end
