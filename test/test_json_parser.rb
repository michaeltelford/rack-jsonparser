require 'minitest/autorun'
require 'json_parser'

class TestJSONParser < Minitest::Test
  def test_constructor_defaults
    app = proc {}
    m = Rack::JSONParser.new app

    assert_equal app, m.instance_variable_get(:@app)
    assert m.instance_variable_get(:@transform_request)
    assert m.instance_variable_get(:@transform_response)
  end

  def test_pass_through_without_content_type_headers
    request       = {}
    response      = [200, {}, ['It works!']]
    expected_req  = {}
    expected_res  = [200, {}, ['It works!']]

    app = proc do |env|
      assert_equal expected_req, env
      response
    end
    m = Rack::JSONParser.new app

    assert_equal expected_res, m.call(request)
  end

  def test_pass_through_using_constructor
    request       = { 'CONTENT_TYPE' => 'application/json' }
    response      = [200, { 'CONTENT_TYPE' => 'application/json' },
                      ['It works!']]
    expected_req  = { 'CONTENT_TYPE' => 'application/json' }
    expected_res  = [200, { 'CONTENT_TYPE' => 'application/json' },
                      ['It works!']]

    app = proc do |env|
      assert_equal expected_req, env
      response
    end
    m = Rack::JSONParser.new app,
                             transform_request: false,
                             transform_response: false

    assert_equal expected_res, m.call(request)
  end

  def test_constructor_processes_request_only
    request = {
        'CONTENT_TYPE' => 'application/json',
        'rack.input' =>
          '{ "forenames": ["Napoleon", "Neech"], "surname": "Manly" }'
      }
    response = [200, { 'CONTENT_TYPE' => 'application/json' },
      ['{ "forenames": ["Napoleon", "Neech"], "surname": "Manly" }']]
    expected_req = {
      'CONTENT_TYPE' => 'application/json',
      'rack.input' =>
        '{ "forenames": ["Napoleon", "Neech"], "surname": "Manly" }',
      'payload' => {
        'forenames' => %w[Napoleon Neech], 'surname' => 'Manly'
      }
    }
    expected_res = [200, { 'CONTENT_TYPE' => 'application/json' },
      ['{ "forenames": ["Napoleon", "Neech"], "surname": "Manly" }']]

    app = proc do |env|
      assert_equal expected_req, env
      response
    end
    m = Rack::JSONParser.new app, transform_response: false

    assert_equal expected_res, m.call(request)
  end

  def test_constructor_processes_response_only
    request = {
        'CONTENT_TYPE' => 'application/json',
        'rack.input' =>
          '{"forenames":["Napoleon", "Neech"],"surname":"Manly"}'
      }
    response = [200, { 'CONTENT_TYPE' => 'application/json' },
      { 'full_name' => 'Napoleon Neech Manly' }]
    expected_req = {
        'CONTENT_TYPE' => 'application/json',
        'rack.input' =>
          '{"forenames":["Napoleon", "Neech"],"surname":"Manly"}'
      }
    expected_res = [200, {
        'CONTENT_TYPE' => 'application/json',
        'CONTENT_LENGTH' => '36'
      },
      ['{"full_name":"Napoleon Neech Manly"}']]

    app = proc do |env|
      assert_equal expected_req, env
      response
    end
    m = Rack::JSONParser.new app, transform_request: false

    assert_equal expected_res, m.call(request)
  end

  def test_parser_processes_request_and_response
    request = {
        'CONTENT_TYPE' => 'application/json',
        'rack.input' =>
          '{ "forenames": ["Napoleon", "Neech"], "surname": "Manly" }'
      }
    response = [200, { 'CONTENT_TYPE' => 'application/json' },
      { 'full_name' => 'Napoleon Neech Manly' }]
    expected_req = {
        'CONTENT_TYPE' => 'application/json',
        'rack.input' =>
          '{ "forenames": ["Napoleon", "Neech"], "surname": "Manly" }',
        'payload' => {
          'forenames' => %w[Napoleon Neech], 'surname' => 'Manly'
        }
      }
    expected_res = [200, {
        'CONTENT_TYPE' => 'application/json',
        'CONTENT_LENGTH' => '36'
      },
      ['{"full_name":"Napoleon Neech Manly"}']]

    app = proc do |env|
      assert_equal expected_req, env
      response
    end
    m = Rack::JSONParser.new app

    assert_equal expected_res, m.call(request)
  end

  def test_parser_processes_string_type
    request = {}
    response = [200, { 'CONTENT_TYPE' => 'application/json' }, 'hello world']
    expected_req = {}
    expected_res = [200, {
        'CONTENT_TYPE' => 'application/json',
        'CONTENT_LENGTH' => '13'
      }, ["\"hello world\""]]

    app = proc do |env|
      assert_equal expected_req, env
      response
    end
    m = Rack::JSONParser.new app

    assert_equal expected_res, m.call(request)
  end

  def test_parser_processes_object_type
    obj = OpenStruct.new(name: 'Michael', pets: %w[Harold Molly]).freeze
    request = {}
    response = [200, { 'CONTENT_TYPE' => 'application/json' }, obj]
    expected_req = {}
    expected_res = [200, {
        'CONTENT_TYPE' => 'application/json',
        'CONTENT_LENGTH' => '74'
      }, ["{\"^o\":\"OpenStruct\",\"table\":{\":name\":\"Michael\",\
\":pets\":[\"Harold\",\"Molly\"]}}"]]

    app = proc do |env|
      assert_equal expected_req, env
      response
    end
    m = Rack::JSONParser.new app

    assert_equal expected_res, m.call(request)
  end

  def test_content_type_processes_request_only
    request = {
        'CONTENT_TYPE' => 'application/json',
        'rack.input' =>
          '{ "forenames": ["Napoleon", "Neech"], "surname": "Manly" }'
      }
    response = [200, {},
      ['{ "forenames": ["Napoleon", "Neech"], "surname": "Manly" }']]
    expected_req = {
      'CONTENT_TYPE' => 'application/json',
      'rack.input' =>
        '{ "forenames": ["Napoleon", "Neech"], "surname": "Manly" }',
      'payload' => {
        'forenames' => %w[Napoleon Neech], 'surname' => 'Manly'
      }
    }
    expected_res = [200, {},
      ['{ "forenames": ["Napoleon", "Neech"], "surname": "Manly" }']]

    app = proc do |env|
      assert_equal(expected_req, env)
      response
    end
    m = Rack::JSONParser.new app

    assert_equal expected_res, m.call(request)
  end

  def test_content_type_processes_response_only
    request = {
        'rack.input' =>
          '{"forenames":["Napoleon", "Neech"],"surname":"Manly"}'
      }
    response = [200, { 'CONTENT_TYPE' => 'application/json' },
      { 'full_name' => 'Napoleon Neech Manly' }]
    expected_req = {
        'rack.input' =>
          '{"forenames":["Napoleon", "Neech"],"surname":"Manly"}'
      }
    expected_res = [200, {
        'CONTENT_TYPE' => 'application/json',
        'CONTENT_LENGTH' => '36'
      },
      ['{"full_name":"Napoleon Neech Manly"}']]

    app = proc do |env|
      assert_equal expected_req, env
      response
    end
    m = Rack::JSONParser.new app

    assert_equal expected_res, m.call(request)
  end

  #-------------------------- Transform Request -------------------------

  def test_transform_request_is_true
    m = Rack::JSONParser.new(proc {})
    assert m.send :transform_request?,
        'CONTENT_TYPE' => 'application/json',
        'rack.input' =>
          '{ "forenames": ["Napoleon", "Neech"], "surname": "Manly" }'
  end

  def test_transform_request_is_false_with_configuration
    m = Rack::JSONParser.new(proc {}, transform_request: false)
    refute m.send :transform_request?, {
      'CONTENT_TYPE' => 'application/json',
      'rack.input' =>
        '{ "forenames": ["Napoleon", "Neech"], "surname": "Manly" }'
    }
  end

  def test_transform_request_is_false_with_empty_request
    m = Rack::JSONParser.new(proc {})
    refute m.send :transform_request?, {}
  end

  def test_transform_request_is_false_with_missing_rack_input
    m = Rack::JSONParser.new(proc {})
    refute m.send :transform_request?, {
      'CONTENT_TYPE' => 'application/json',
    }
  end

  def test_transform_request_is_false_with_missing_content_type
    m = Rack::JSONParser.new(proc {})
    refute m.send :transform_request?, {
      'rack.input' =>
        '{ "forenames": ["Napoleon", "Neech"], "surname": "Manly" }'
    }
  end

  #-------------------------- Transform Response -------------------------

  def test_transform_response_is_true
    m = Rack::JSONParser.new(proc {})
    assert m.send :transform_response?,
        { 'CONTENT_TYPE' => 'application/json' },
        { "forenames" => ["Napoleon", "Neech"], "surname" => "Manly" }
  end

  def test_transform_response_is_false_with_configuration
    m = Rack::JSONParser.new(proc {}, transform_response: false)
    refute m.send :transform_response?,
        { 'CONTENT_TYPE' => 'application/json' },
        { "forenames" => ["Napoleon", "Neech"], "surname" => "Manly" }
  end

  def test_transform_response_is_false_with_empty_response
    m = Rack::JSONParser.new(proc {})
    refute m.send :transform_response?, {}, {}
  end

  def test_transform_response_is_false_with_missing_body
    m = Rack::JSONParser.new(proc {})
    refute m.send :transform_response?, {
      'CONTENT_TYPE' => 'application/json'
    }, nil
  end

  def test_transform_response_is_false_with_missing_content_type
    m = Rack::JSONParser.new(proc {})
    refute m.send :transform_response?, {}, {
      "forenames" => ["Napoleon", "Neech"], "surname" => "Manly"
    }
  end
end
