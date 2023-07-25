require "active_support/core_ext/hash"
require "active_support/core_ext/object/deep_dup"

module HTTPigeon
  class Logger
    attr_reader :event_type, :log_redactor, :start_time, :end_time

    def initialize(event_type: nil, additional_filter_keys: nil, log_filters: nil)
      @event_type = event_type || HTTPigeon.default_event_type

      hash_filters, string_filters = (log_filters || []).partition { |filter| filter.type.to_sym == :hash }
      hash_filter_keys = HTTPigeon.default_filter_keys + additional_filter_keys.to_a + hash_filters.map(&:pattern)
      @log_redactor = HTTPigeon.log_redactor || HTTPigeon::LogRedactor.new(hash_filter_keys: hash_filter_keys, string_filters: string_filters)
    end

    def log(faraday_env, data = {})
      base_log_data = { event_type: event_type }
      log_data = build_log_data(faraday_env, data).merge(base_log_data)

      HTTPigeon.event_logger.nil? ? log_to_stdout(log_data) : HTTPigeon.event_logger.log(log_data)
    rescue StandardError => e
      HTTPigeon.exception_notifier.notify_exception(e) if HTTPigeon.notify_all_exceptions
      raise e if ['development', 'test'].include?(ENV['RAILS_ENV'].to_s)
    end

    def on_request_start
      @start_time = Time.current
    end

    def on_request_finish
      @end_time = Time.current
    end

    private

    def build_log_data(env, data)
      log_data = data.deep_dup
      request_id = env.request_headers.transform_keys(&:downcase)['x-request-id']
      request_latency = end_time - start_time if end_time.present? && start_time.present?

      log_data[:request] = {
        method: env.method,
        url: env.url.to_s,
        headers: filter(env.request_headers),
        body: filter(env.request_body),
        host: env.url.host,
        path: env.url.path
      }

      log_data[:response] = {
        headers: filter(env.response_headers),
        body: filter(env.response_body),
        status: env.status
      }

      log_data[:metadata] = {
        latency: request_latency,
        identifier: request_id,
        protocol: env.url.scheme
      }

      if log_data[:error].present?
        error = log_data.delete(:error)
        log_data[:error] = {
          type: error.class.name,
          message: error.message,
          backtrace: error.backtrace.last(10)
        }
      end

      log_data
    end

    def filter(body)
      return {} if body.blank?

      body = JSON.parse(body) if body.is_a?(String)
      log_redactor.redact(body)
    rescue JSON::ParserError
      log_redactor.redact(body)
    end

    def log_to_stdout(log_data)
      Logger.new($stdout).log(1, log_data.to_json)
    end
  end
end
