require_relative 'errors'
require_relative 'fuse_config'
require_relative 'memory_store'
require_relative '../middleware/circuit_breaker'

module HTTPigeon
  module CircuitBreaker
    class Fuse
      STATE_OPEN = 'open'.freeze
      STATE_HALF_OPEN = 'half_open'.freeze
      STATE_CLOSED = 'closed'.freeze

      def self.from_options(options)
        new(FuseConfig.new(options))
      end

      attr_reader :service_id, :config, :storage

      def initialize(config)
        @config = config
        @service_id = config.service_id.to_s
        @storage = CircuitBreaker::MemoryStore.new(config.sample_window)
        @open_storage_key = "circuit:#{service_id}:#{STATE_OPEN}"
        @half_open_storage_key = "circuit:#{service_id}:#{STATE_HALF_OPEN}"
        @state_change_syncer = Mutex.new
      end

      def execute(request_id: nil)
        @request_id = request_id

        if open?
          record_tripped!

          config.on_open_circuit.call(config.null_response, config.circuit_open_error)
        else
          begin
            response = yield
            server_maintenance_timeout = response.headers[config.maintenance_mode_header].to_i

            if server_maintenance_timeout.positive?
              record_failure!
              open!(
                {
                  expires_in: server_maintenance_timeout,
                  # for logging purposes. can't log expires_in because it might be overridden if greater than max
                  server_maintenance_timeout: server_maintenance_timeout
                }
              )

              return config.on_open_circuit.call(response, config.circuit_open_error)
            end

            record_success!
            response
          rescue Faraday::Error => e
            record_failure! if e.response_status >= 500 || config.error_codes_watchlist.include?(e.response_status)

            raise e
          end
        end
      end

      def open?
        storage.key?(open_storage_key)
      end

      def half_open?
        storage.key?(half_open_storage_key)
      end

      def failure_count
        storage.get(stat_storage_key(:failure)).to_i
      end

      def success_count
        storage.get(stat_storage_key(:success)).to_i
      end

      def tripped_count
        storage.get(stat_storage_key(:tripped)).to_i
      end

      def failure_rate
        total_stats = success_count + failure_count + tripped_count

        return 0.0 unless total_stats.positive?

        (total_stats - success_count).to_f / total_stats
      end

      def reset!
        state_change_syncer.synchronize { storage.reset! }
      end

      private

      attr_reader :open_storage_key, :half_open_storage_key, :state_change_syncer, :request_id

      def failed_request?(response)
        response.status.nil? || response.status >= 500 || config.error_codes_watchlist.include?(response.status)
      end

      def should_open?
        return false if failure_count < config.min_failures_count

        failure_count >= config.max_failures_count || failure_rate >= config.failure_rate_threshold
      end

      def close!(opts = {})
        state_change_syncer.synchronize do
          # We only close the circuit if there have been at least one successful request during the current sample window
          return unless success_count.positive?

          # For the circuit to be closable, it must NOT be open AND
          # it must be currently half open (i.e half_open_storage_key must be true)
          # Otherwise, we return early
          return unless !open? && storage.delete(half_open_storage_key)

          # reset failures count for current sample window
          # so that we can only trip the circuit if we reach the min failures threshold again
          storage.delete(stat_storage_key(:failure))
        end

        log_circuit_event('circuit_closed', STATE_CLOSED, opts)
      end

      def open!(opts = {})
        state_change_syncer.synchronize do
          return if open?

          trip!(type: :full, **opts)

          # reset failures count for current sample window so that the circuit doesn't re-open immediately
          # if a request fails while in half_open state
          storage.delete(stat_storage_key(:failure))
        end

        opts.delete(:expires_in) # don't log expires_in key as it may be overridden if greater than max
        log_circuit_event('circuit_opened', STATE_OPEN, opts)
      end

      def half_open!(opts = {})
        state_change_syncer.synchronize do
          return if open? || half_open?

          trip!(type: :partial, **opts)
        end

        log_circuit_event('circuit_half_opened', STATE_HALF_OPEN, opts)
      end

      def trip!(type:, **opts)
        if type == :full
          storage.set(open_storage_key, true, { expires_in: config.open_circuit_sleep_window }.merge(opts))
          storage.set(half_open_storage_key, true, { expires_in: config.sample_window }.merge(opts))
        elsif type == :partial
          storage.set(half_open_storage_key, true, { expires_in: config.sample_window }.merge(opts))
        end
      end

      def record_success!
        record_stat(:success)

        close! if half_open?
      end

      def record_failure!
        record_stat(:failure)

        open! if should_open? && (!half_open? || !open?)
        half_open! if !half_open? && failure_count >= config.min_failures_count
      end

      def record_tripped!
        record_stat(:tripped)
        log_circuit_event('execution_skipped', STATE_OPEN)
      end

      def record_stat(outcome, value = 1)
        storage.increment(stat_storage_key(outcome), value, expires_in: config.sample_window)
      end

      def stat_storage_key(outcome)
        "run_stat:#{service_id}:#{outcome}"
      end

      def log_circuit_event(event, status, payload = {})
        return unless HTTPigeon.log_circuit_events

        payload = {
          event_type: "httpigeon.fuse.#{event}",
          service_id: service_id,
          request_id: request_id,
          circuit_state: status,
          success_count: success_count,
          failure_count: failure_count,
          failure_rate: failure_rate,
          recorded_at: Time.now.to_i
        }.merge(payload).compact

        HTTPigeon.event_logger&.log(payload) || HTTPigeon.stdout_logger.log(1, payload.to_json)
      end
    end
  end
end
