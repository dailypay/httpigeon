require 'faraday'

module HTTPigeon
  module CircuitBreaker
    class NullResponse < Faraday::Response
      attr_reader :api_response, :exception

      def initialize(response = nil, exception = nil)
        @api_response = response
        @exception = exception
        super(status: 503, response_headers: response&.headers || {})
      end
    end

    class FuseConfig
      DEFAULT_MM_TIMEOUT_HEADER = 'X-Maintenance-Mode-Timeout'.freeze

      attr_reader :max_failures_count,
                  :min_failures_count,
                  :failure_rate_threshold,
                  :sample_window,
                  :open_circuit_sleep_window,
                  :on_circuit_closed,
                  :on_circuit_opened,
                  :open_circuit_handler,
                  :error_codes_watchlist,
                  :maintenance_mode_header,
                  :service_id

      def initialize(fuse_options = {})
        @service_id = fuse_options[:service_id].presence || raise(ArgumentError, 'service_id is required')
        @max_failures_count = fuse_options[:max_failures_count] || HTTPigeon.fuse_max_failures_count
        @min_failures_count = fuse_options[:min_failures_count] || HTTPigeon.fuse_min_failures_count
        @failure_rate_threshold = fuse_options[:failure_rate_threshold] || HTTPigeon.fuse_failure_rate_threshold
        @sample_window = fuse_options[:sample_window] || HTTPigeon.fuse_sample_window
        @open_circuit_sleep_window = fuse_options[:open_circuit_sleep_window] || HTTPigeon.fuse_open_circuit_sleep_window
        @error_codes_watchlist = fuse_options[:error_codes_watchlist].to_a | HTTPigeon.fuse_error_codes_watchlist.to_a
        @maintenance_mode_header = fuse_options[:maintenance_mode_header] || DEFAULT_MM_TIMEOUT_HEADER

        @on_circuit_closed = HTTPigeon.fuse_on_circuit_closed
        @on_circuit_opened = HTTPigeon.fuse_on_circuit_opened
        @open_circuit_handler = if HTTPigeon.fuse_open_circuit_handler.respond_to?(:call)
                                  HTTPigeon.fuse_open_circuit_handler
                                else
                                  ->(api_response, exception) { null_response(api_response, exception) }
                                end
      end

      def to_h
        {
          service_id: service_id,
          max_failures_count: max_failures_count,
          min_failures_count: min_failures_count,
          failure_rate_threshold: failure_rate_threshold,
          sample_window: sample_window,
          open_circuit_sleep_window: open_circuit_sleep_window,
          error_codes_watchlist: error_codes_watchlist,
          maintenance_mode_header: maintenance_mode_header
        }
      end

      def null_response(api_response = nil, exception = nil)
        NullResponse.new(api_response, exception)
      end

      def circuit_open_error
        CircuitOpenError.new(service_id)
      end
    end
  end
end
