require_relative "../test_helper"

class HTTPigeon::RequestTest < HTTPigeon::TestCase
  describe '.get' do
    it 'makes request with expected arguments' do
      endpoint = 'https://dummyjson.com/users/search'
      query = { q: 'John' }
      event_type = 'some.event'
      headers = { 'Foo' => 'Barzzz' }

      request_mock = Minitest::Mock.new
      request_mock.expect(:response, 'faraday-response')
      request_mock.expect(:run, { hello: 'hi' }) do |**kwargs|
        assert_equal kwargs[:method], :get
        assert_empty kwargs[:path]
        assert_equal kwargs[:payload], query
      end

      request_on_new = ->(**kwargs) do
        assert_equal kwargs[:base_url], endpoint
        assert_equal kwargs[:headers], headers
        assert_equal kwargs[:event_type], event_type
        assert_equal kwargs[:log_filters], []

        request_mock
      end

      HTTPigeon::Request.stub(:new, request_on_new) do
        response = HTTPigeon::Request.get(endpoint, query, headers, event_type)

        assert response.is_a?(HTTPigeon::Response)
        assert_equal response.parse_response, { hello: 'hi' }
        assert_equal response.raw_response, 'faraday-response'
        assert_mock request_mock
      end
    end
  end

  describe '.post' do
    it 'makes request with expected arguments' do
      endpoint = 'https://dummyjson.com/users/add'
      payload = { 'firstName': 'John', 'lastName': 'Doe' }
      event_type = 'some.event'
      headers = { 'Foo' => 'Barzzz' }

      request_mock = Minitest::Mock.new
      request_mock.expect(:response, 'faraday-response')
      request_mock.expect(:run, { hello: 'hi' }) do |**kwargs|
        assert_equal kwargs[:method], :post
        assert_empty kwargs[:path]
        assert_equal kwargs[:payload], payload
      end

      request_on_new = ->(**kwargs) do
        assert_equal kwargs[:base_url], endpoint
        assert_equal kwargs[:headers], headers
        assert_equal kwargs[:event_type], event_type
        assert_equal kwargs[:log_filters], []

        request_mock
      end

      HTTPigeon::Request.stub(:new, request_on_new) do
        response = HTTPigeon::Request.post(endpoint, payload, headers, event_type)

        assert response.is_a?(HTTPigeon::Response)
        assert_equal response.parse_response, { hello: 'hi' }
        assert_equal response.raw_response, 'faraday-response'
        assert_mock request_mock
      end
    end
  end

  describe '#new' do
    context 'when a custom logger is not provided' do
      it 'uses the default :httpigeon_logger' do
        event_type = 'some.event'
        filter_keys = [:super_secret]
        logger_mock = Minitest::Mock.new
        logger_mock.expect(:call, nil) { |args| args[:event_type] == event_type && args[:additional_filter_keys] == filter_keys }

        HTTPigeon::Logger.stub(:new, logger_mock) do
          request = HTTPigeon::Request.new(base_url: 'https://www.example.com', event_type: event_type, filter_keys: filter_keys)

          assert_mock logger_mock
          assert_equal 'application/json', request.connection.headers['Accept']
        end
      end
    end

    context 'when a custom logger is provided' do
      it 'uses the custom logger' do
        logger = Logger.new($stdout)
        logger_mock = Minitest::Mock.new
        logger_mock.expect(:call, nil) { |args| args.keys == %i[event_type filter_keys] }

        HTTPigeon::Logger.stub(:new, logger_mock) do
          HTTPigeon::Request.new(base_url: 'http://www.example.com', logger: logger)

          refute_mock logger_mock
        end
      end
    end
  end
end
