require 'faraday'

module HTTPigeon
  module Middleware
    class CircuitBreaker < Faraday::Middleware
      class FailedRequestError < Faraday::Error; end

      def initialize(app, fuse_config)
        super(app)

        @fuse_config = fuse_config
      end

      def on_complete(env)
        return unless failed_request?(env.status)

        raise FailedRequestError, response_values(env)
      end

      private

      def failed_request?(response_status)
        response_status.nil? || response_status >= 500 || @fuse_config.error_codes_watchlist.include?(response_status)
      end

      def response_values(env)
        {
          status: env.status,
          headers: env.response_headers,
          body: env.body,
          request: {
            method: env.method,
            url: env.url,
            url_path: env.url.path,
            params: query_params(env),
            headers: env.request_headers,
            body: env.request_body
          }
        }
      end

      def query_params(env)
        env.request.params_encoder ||= Faraday::Utils.default_params_encoder
        env.params_encoder.decode(env.url.query)
      end
    end
  end
end

Faraday::Response.register_middleware(circuit_breaker: HTTPigeon::Middleware::CircuitBreaker)
