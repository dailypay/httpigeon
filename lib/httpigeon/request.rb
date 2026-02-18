require "faraday"
require "active_support/core_ext/hash"
require "active_support/isolated_execution_state"
require "active_support/core_ext/time"
require_relative "middleware/httpigeon_logger"

module HTTPigeon
  class Request
    REQUEST_ID_HEADER = 'X-Request-Id'.freeze
    ALLOWED_METHODS = %i[get post put patch delete head options].freeze

    class << self
      def get(endpoint, query = {}, headers = {}, event_type = nil, log_filters = [])
        request = new(base_url: endpoint, headers: headers, event_type: event_type, log_filters: log_filters)
        request.run(method: :get, path: '', payload: query) do |req|
          yield(req) if block_given?
        end
      end

      def post(endpoint, payload, headers = {}, event_type = nil, log_filters = [])
        request = new(base_url: endpoint, headers: headers,  event_type: event_type, log_filters: log_filters)
        request.run(method: :post, path: '', payload: payload) do |req|
          yield(req) if block_given?
        end
      end

      def put(endpoint, payload, headers = {}, event_type = nil, log_filters = [])
        request = new(base_url: endpoint, headers: headers, event_type: event_type, log_filters: log_filters)
        request.run(method: :put, path: '', payload: payload) do |req|
          yield(req) if block_given?
        end
      end

      def delete(endpoint, query = {}, headers = {}, event_type = nil, log_filters = [])
        request = new(base_url: endpoint, headers: headers, event_type: event_type, log_filters: log_filters)
        request.run(method: :delete, path: '', payload: query) do |req|
          yield(req) if block_given?
        end
      end
    end

    attr_reader :connection, :response, :base_url, :fuse

    delegate :status, :body, :parsed_response, to: :response, prefix: true

    def initialize(base_url:, options: nil, headers: nil, adapter: nil, logger: nil, event_type: nil, log_filters: nil, fuse_config: nil)
      @base_url = URI.parse(base_url)

      request_headers = default_headers(request_id: SecureRandom.uuid).merge(headers.to_h)
      fuse_config_opts = { service_id: @base_url.host }.merge(fuse_config.to_h)
      @fuse = CircuitBreaker::Fuse.from_options(fuse_config_opts)

      base_connection = Faraday.new(url: @base_url.to_s).tap do |config|
        config.headers.deep_merge!(request_headers)
        config.options.merge!(options.to_h)
        config.response :circuit_breaker, fuse.config if HTTPigeon.mount_circuit_breaker
        config.response :httpigeon_logger, logger if logger.is_a?(HTTPigeon::Logger)
      end

      @connection = if block_given?
                      yield(base_connection) && base_connection
                    else
                      base_connection.tap do |faraday|
                        faraday.headers.deep_merge!(request_headers)
                        faraday.options.merge!(options.to_h)
                        faraday.request :url_encoded
                        faraday.adapter adapter || Faraday.default_adapter
                        faraday.response :httpigeon_logger, default_logger(event_type, log_filters) unless logger.is_a?(HTTPigeon::Logger)
                      end
                    end
    end

    def run(method: :get, path: '/', payload: {})
      sym_method = method.to_sym

      raise ArgumentError, "Invalid or unsupported HTTP method: #{method}" unless ALLOWED_METHODS.include?(sym_method)

      unless [:get, :delete].include?(sym_method)
        payload = payload.presence&.to_json
        connection.headers['Content-Type'] = 'application/json'
      end

      connection.headers[REQUEST_ID_HEADER] = SecureRandom.uuid if HTTPigeon.auto_generate_request_id

      raw_response = if HTTPigeon.mount_circuit_breaker
                       fuse.execute(request_id: connection.headers[REQUEST_ID_HEADER]) do
                         connection.send(method, path, payload) do |request|
                           yield(request) if block_given?
                         end
                       end
                     else
                       connection.send(method, path, payload) do |request|
                         yield(request) if block_given?
                       end
                     end

      @response = HTTPigeon::Response.new(self, raw_response)
    end

    private

    attr_reader :logger, :event_type, :log_filters

    def default_logger(event_type, log_filters)
      HTTPigeon::Logger.new(event_type: event_type, log_filters: log_filters)
    end

    def default_headers(request_id: nil)
      { 'Accept' => 'application/json', REQUEST_ID_HEADER => request_id }.compact
    end
  end
end
