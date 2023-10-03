require_relative "../test_helper"

class HTTPigeon::LoggerTest < HTTPigeon::TestCase
  describe '#new' do
    context 'when a custom log redactor is defined' do
      it 'uses the custom redactor' do
        HTTPigeon.stub(:log_redactor, :my_custom_log_redactor) do
          logger = HTTPigeon::Logger.new

          assert_equal :my_custom_log_redactor, logger.log_redactor
        end
      end
    end

    context 'when a custom log redactor is not defined' do
      it 'uses the HTTPigeon redactor' do
        filter_keys = [:key_1, :key_2]

        HTTPigeon.stub(:log_redactor, nil) do
          logger = HTTPigeon::Logger.new(log_filters: filter_keys)

          assert_instance_of HTTPigeon::LogRedactor, logger.log_redactor
        end
      end
    end
  end

  describe '#log' do
    let(:event_type) { nil }
    let(:filter_keys) { %w[account_number ssn X-Subscription-Key x-api-token] }
    let(:logger) { HTTPigeon::Logger.new(event_type: event_type, log_filters: filter_keys) }
    let(:error) { TypeError.new('Not my type') }
    let(:base_data) { { something: 'important', error: error } }
    let(:response_status) { 200 }
    let(:faraday_env) do
      OpenStruct.new(
        {
          method: 'post',
          url: OpenStruct.new(
            {
              to_s: 'http://example.com/home',
              host: 'example.com',
              path: 'home',
              scheme: 'https'
            }
          ),
          request_headers: { 'X-Request-Id' => 'abc-012-xyz-789', 'X-Subscription-Key' => 'super-secret-key', 'X-API-Token' => 'super-top-secret-token' },
          request_body: { foo: 'barzz' },
          response_headers: { 'X-Request-Id' => 'abc-012-xyz-789' },
          response_body: response_body,
          status: response_status
        }
      )
    end

    let(:log_payload) do
      {
        something: 'important',
        request: {
          method: 'post',
          url: 'http://example.com/home',
          headers: { 'X-Request-Id' => 'abc-012-xyz-789', 'X-Subscription-Key' => 'super...[FILTERED]', 'X-API-Token' => 'super-...[FILTERED]' },
          body: { foo: 'barzz' },
          host: 'example.com',
          path: 'home'
        },
        response: {
          headers: { 'X-Request-Id' => 'abc-012-xyz-789' },
          body: filtered_response_body,
          status: response_status
        },
        metadata: {
          latency: nil,
          identifier: 'abc-012-xyz-789',
          protocol: 'https'
        },
        error: {
          type: 'TypeError',
          message: 'Not my type',
          backtrace: error.backtrace.last(10)
        }
      }
    end

    before { error.set_backtrace(caller) }

    context 'when the response body is valid JSON' do
      let(:event_type) { 'custom.event' }
      let(:response_body) { { account_number: '0000000100100011', ssn: '123-45-6789', ifdis: 'dendat' } }
      let(:filtered_response_body) { { account_number: '00000...[FILTERED]', ssn: '123...[FILTERED]', ifdis: 'dendat' } }

      context 'when there is a custom event logger' do
        before do
          class MyCustomLogger
            def log(data = {}); end
          end
        end

        after { HTTPigeon::LoggerTest.send :remove_const, "MyCustomLogger" }

        it 'logs the filtered payload using the custom event logger' do
          on_log = ->(payload) { assert_equal payload, log_payload.merge(event_type: event_type) }

          HTTPigeon.stub(:event_logger, MyCustomLogger.new) do
            HTTPigeon.event_logger.stub(:log, on_log) do
              logger.log(faraday_env, base_data)
            end
          end
        end
      end

      context 'when there is no custom event logger' do
        it 'logs the filtered payload with ruby logger' do
          on_log = ->(*args) { assert_equal [1, { event_type: event_type, data: log_payload }.to_json, nil], args }
          ruby_logger_on_new = ->(arg) { assert_equal $stdout, arg }

          Logger.stub(:new, ruby_logger_on_new) do
            Logger.stub_any_instance(:log, on_log) do
              logger.log(faraday_env, base_data)
            end
          end
        end
      end
    end

    context 'when the response body is invalid JSON' do
      let(:response_status) { 400 }
      let(:response_body) { 'not found' }
      let(:filtered_response_body) { response_body }

      it 'logs the original payload' do
        on_log = ->(*args) { assert_equal [1, { event_type: HTTPigeon.default_event_type, data: log_payload }.to_json, nil], args }
        ruby_logger_on_new = ->(arg) { assert_equal $stdout, arg }

        Logger.stub(:new, ruby_logger_on_new) do
          Logger.stub_any_instance(:log, on_log) do
            logger.log(faraday_env, base_data)
          end
        end
      end
    end
  end
end
