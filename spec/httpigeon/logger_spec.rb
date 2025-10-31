require 'spec_helper'

describe HTTPigeon::Logger do
  describe '#log_redactor' do
    subject(:log_redactor) { described_class.new(log_filters: %w[filter_1 filter_2]).log_redactor }

    before { allow(HTTPigeon).to receive(:log_redactor).and_return(custom_log_redactor) }

    context 'when a custom log redactor is defined' do
      let(:custom_log_redactor) { :my_custom_log_redactor }

      specify { expect(log_redactor).to eq(:my_custom_log_redactor) }
    end

    context 'when a custom log redactor is not defined' do
      let(:custom_log_redactor) { nil }

      specify { expect(log_redactor).to be_a(HTTPigeon::LogRedactor) }
    end
  end

  describe '#log' do
    subject(:log) { described_class.new(event_type: event_type, log_filters: filter_keys).log(faraday_env, base_data) }

    let(:event_type) { nil }
    let(:filter_keys) { %w[account_number ssn::[FILTERED] X-Subscription-Key x-api-token /(client_secret=)([0-9a-z]+)*/] }
    let(:error) { TypeError.new('Not my type') }
    let(:base_data) { { something: 'important', error: error } }
    let(:response_status) { 200 }
    let(:faraday_env) do
      # rubocop:disable Lint/StructNewOverride
      Struct.new(:method, :url, :request_headers, :request_body, :response_headers, :response_body, :status, keyword_init: true).new(
        {
          method: 'post',
          url: Struct.new(:to_s, :host, :path, :scheme, keyword_init: true).new(
            {
              to_s: 'http://example.com/home?client_id=client_007&client_secret=agent0047&dark_mode=true',
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
      # rubocop:enable Lint/StructNewOverride
    end

    let(:log_payload) do
      {
        something: 'important',
        request: {
          method: 'post',
          url: 'http://example.com/home?client_id=client_007&client_secret=age...[FILTERED]&dark_mode=true',
          headers: { 'X-Request-Id' => 'abc-012-xyz-789', 'X-Subscription-Key' => 'sup...[FILTERED]', 'X-API-Token' => 'super-...[FILTERED]' },
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
      let(:filtered_response_body) { { account_number: '000...[FILTERED]', ssn: '[FILTERED]', ifdis: 'dendat' } }

      context 'when there is a custom event logger' do
        it 'logs the filtered payload using the custom event logger' do
          custom_logger = double('my-custom-logger')
          allow(custom_logger).to receive(:log)
          allow(HTTPigeon).to receive(:event_logger).and_return(custom_logger)

          log

          expect(custom_logger).to have_received(:log).with(log_payload.merge(event_type: event_type))
        end
      end

      context 'when there is no custom event logger' do
        it 'logs the filtered payload with ruby logger' do
          logger_double = instance_double(Logger)
          allow(logger_double).to receive(:log)
          allow(HTTPigeon).to receive(:stdout_logger).and_return(logger_double)

          log

          expect(logger_double).to have_received(:log).with(1, log_payload.merge(event_type: event_type).to_json)
        end
      end
    end

    context 'when the response body is invalid JSON' do
      let(:response_status) { 400 }
      let(:response_body) { 'not found' }
      let(:filtered_response_body) { response_body }

      it 'logs the original payload' do
        logger_double = instance_double(Logger)
        allow(logger_double).to receive(:log)
        allow(HTTPigeon).to receive(:stdout_logger).and_return(logger_double)

        log

        expect(logger_double).to have_received(:log).with(1, log_payload.merge(event_type: HTTPigeon.default_event_type).to_json)
      end
    end

    context 'when there is an unexpected error' do
      let(:response_body) { 'does-not-matter' }
      let(:notifier_double) { double('exception-notifier') }

      before do
        allow_any_instance_of(HTTPigeon).to receive(:event_logger).and_raise(NoMethodError, 'no can do!')
        allow(notifier_double).to receive(:notify_exception)
        allow(HTTPigeon).to receive(:exception_notifier).and_return(notifier_double)
      end

      it 'notifies exception if :notify_all_exceptions is on' do
        allow(HTTPigeon).to receive(:notify_all_exceptions).and_return(true)

        log

        expect(notifier_double).to have_received(:notify_exception).with(an_instance_of(NoMethodError))
      end

      it 'does not notify exception if :notify_all_exceptions is off' do
        allow(HTTPigeon).to receive(:notify_all_exceptions).and_return(false)

        log

        expect(notifier_double).not_to have_received(:notify_exception)
      end
    end
  end

  describe '#on_request_start' do
    subject(:on_request_start) { logger.on_request_start }

    let(:logger) { described_class.new }

    it 'records start time' do
      current_time = Time.current
      allow(Time).to receive(:current).and_return(current_time)

      on_request_start

      expect(logger.start_time).to eq(current_time)
    end
  end

  describe '#on_request_finish' do
    subject(:on_request_finish) { logger.on_request_finish }

    let(:logger) { described_class.new }

    it 'records end time' do
      current_time = Time.current
      allow(Time).to receive(:current).and_return(current_time)

      on_request_finish

      expect(logger.end_time).to eq(current_time)
    end
  end
end
