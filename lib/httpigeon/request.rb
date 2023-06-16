require "faraday"
require "active_support/core_ext/hash"
require "active_support/isolated_execution_state"
require "active_support/core_ext/time"
require_relative "middleware/httpigeon_logger"

module HTTPigeon
  class Request
    attr_reader :connection, :response, :parsed_response

    delegate :status, :body, to: :response, prefix: true

    def initialize(base_url:, options: nil, headers: nil, adapter: nil, logger: nil, event_type: nil, filter_keys: nil)
      @base_url = base_url
      @event_type = event_type
      @filter_keys = filter_keys || []
      @logger = logger || default_logger

      request_headers = default_headers.merge(headers.to_h)
      base_connection = Faraday.new(url: base_url)

      @connection = if block_given?
                      yield(base_connection) && base_connection
                    else
                      base_connection.tap do |faraday|
                        faraday.headers.deep_merge!(request_headers)
                        faraday.options.merge!(options.to_h)
                        faraday.request :url_encoded
                        faraday.adapter adapter || Faraday.default_adapter
                        faraday.response :httpigeon_logger, @logger
                      end
                    end
    end

    def run(method: :get, path: '/', payload: {})
      unless method.to_sym == :get
        payload = payload.presence&.to_json
        connection.headers['Content-Type'] = 'application/json'
      end

      @response = connection.send(method, path, payload) do |request|
        yield(request) if block_given?
      end

      @parsed_response = parse_response || {}
    end

    private

    attr_reader :path, :logger, :event_type, :filter_keys

    def parse_response
      JSON.parse(response_body).with_indifferent_access unless response_body.empty?
    rescue JSON::ParserError
      response_body.presence
    end

    def default_logger
      HTTPigeon::Logger.new(event_type: event_type, additional_filter_keys: filter_keys)
    end

    def default_headers
      { 'Accept' => 'application/json' }
    end
  end
end
