require 'oj'

module Rack
  # Rack middleware which transforms JSON during the request and response.
  # Configurable so request/response processing can be turned off if desired.
  # Only transforms if the Content-Type header is set and includes
  # 'application/json'. This allows for several types of response content to be
  # served by the application without interference by this middleware. This
  # however requires the client and app to set the 'Content-Type' correctly.
  class JSONParser
    ENV_PAYLOAD_KEY = 'payload'.freeze

    def initialize(app, transform_request: true, transform_response: true)
      @app = app
      @transform_request = transform_request
      @transform_response = transform_response
    end

    # Loads the request JSON string into a Hash instance.
    # Expects the app response body to be an object instance e.g. Hash,
    # putting the object in an array will likely cause unexpected JSON.
    def call(env)
      if transform_request?(env)
        env[ENV_PAYLOAD_KEY] = Oj.load(env['rack.input'])
      end

      status, headers, body = @app.call(env)

      if body && transform_response?(headers)
        body = Oj.dump(body)
        headers['CONTENT_LENGTH'] = body.length.to_s
        body = [body] unless body.is_a?(Array)
      end

      [status, headers, body]
    end

  private

    def transform_request?(env)
      @transform_request &&
        env['CONTENT_TYPE'] == 'application/json' &&
        env['rack.input'] &&
        true # so the return value is true if all prior conditions are true
    end

    def transform_response?(headers)
      @transform_response &&
        headers['CONTENT_TYPE'] == 'application/json' &&
        true # so the return value is true if all prior conditions are true
    end
  end
end
