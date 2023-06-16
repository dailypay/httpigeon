require "faraday/middleware_registry"
require "faraday/middleware"
require "faraday/response"

module HTTPigeon
  module Middleware
    class HTTPigeonLogger < Faraday::Middleware
      def initialize(app, logger)
        super(app)

        @logger = logger
      end

      def call(env)
        logger.on_request_start if logger.respond_to?(:on_request_start)

        super
      rescue StandardError => e
        logger.on_request_finish if logger.respond_to?(:on_request_finish)
        logger.log(env, { error: e })

        raise e
      end

      def on_complete(env)
        logger.on_request_finish if logger.respond_to?(:on_request_finish)
        logger.log(env)
      end

      private

      attr_reader :logger
    end
  end
end

Faraday::Response.register_middleware(httpigeon_logger: HTTPigeon::Middleware::HTTPigeonLogger)
