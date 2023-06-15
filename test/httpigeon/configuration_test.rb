require_relative "../test_helper"

class HTTPigeon::ConfigurationTest < HTTPigeon::TestCase
  describe '#new' do
    it 'sets the expected defaults' do
      config = HTTPigeon::Configuration.new

      assert_equal 'http.outbound', config.default_event_type
      assert_empty config.default_filter_keys
      assert_nil config.event_logger
      assert_nil config.exception_notifier
      refute config.notify_all_exceptions
    end
  end
end
