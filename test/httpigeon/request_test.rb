require_relative "../test_helper"

class HTTPigeon::RequestTest < HTTPigeon::TestCase
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
