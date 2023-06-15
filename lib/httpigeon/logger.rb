require "active_support/core_ext/hash"
require "active_support/core_ext/object/deep_dup"

module HTTPigeon
  class Logger
    def initialize(event_type: nil, additional_filter_keys: nil)
      @event_type = event_type || HTTPigeon.default_event_type
      @additional_filter_keys = additional_filter_keys.to_a.map(&:to_s)
    end

    def log(faraday_env, data = {})
      log_data = build_log_data(faraday_env, data)

      HTTPigeon.event_logger.nil? ? log_to_stdout : HTTPigeon.event_logger.new(event_type).log(log_data)
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

    attr_reader :event_type, :header_log_keys, :additional_filter_keys, :start_time, :end_time

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
        status: env.status,
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

    def filter_keys
      @filter_keys ||= (HTTPigeon.default_filter_keys + additional_filter_keys).map(&:downcase)
    end

    def filter(body)
      return {} if body.blank?

      body = JSON.parse(body) if body.is_a?(String)
      filter_hash(body)
    rescue JSON::ParserError
      body
    end

    def filter_hash(data)
      if data.is_a?(Array)
        data.map { |datum| filter_hash(datum) }
      elsif !data.is_a?(Hash)
        data
      else
        data.to_h do |k, v|
          v = '[FILTERED]' if filter_keys.include?(k.to_s.downcase)

          if v.is_a?(Hash) || v.is_a?(Array)
            [k, filter_hash(v)]
          else
            [k, v]
          end
        end
      end
    end

    def log_to_stdout
      Logger.new($stdout).log(1, { event_type: event_type, data: log_data }.to_json)
    end
  end
end
