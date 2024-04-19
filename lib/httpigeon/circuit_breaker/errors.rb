module HTTPigeon
  module CircuitBreaker
    class Error < StandardError; end

    class CircuitOpenError < Error
      def initialize(service_id)
        super("Circuit open for service: #{service_id}")
      end
    end
  end
end
