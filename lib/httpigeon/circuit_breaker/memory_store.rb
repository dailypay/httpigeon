module HTTPigeon
  module CircuitBreaker
    DataBucket = Struct.new(:value, :expires_at)

    class MemoryStore
      MAX_SAMPLE_WINDOW = 180

      attr_reader :sample_window

      def initialize(sample_window)
        @store = {}
        @mutex = Mutex.new
        @sample_window = [sample_window.to_i, MAX_SAMPLE_WINDOW].min
      end

      def get(key)
        @mutex.synchronize { fetch_bucket(key)&.value }
      end
      alias_method :[], :get

      def set(key, value, opts = {})
        @mutex.synchronize do
          flush(key)

          @store[key] = DataBucket.new(value, relative_expires_at(opts[:expires_in]))
          value
        end
      end
      alias_method :store, :set

      def increment(key, value = 1, opts = {})
        @mutex.synchronize do
          existing_bucket = fetch_bucket(key)

          if existing_bucket
            existing_bucket.expires_at = relative_expires_at(opts[:expires_in])
            existing_bucket.value += value
          else
            @store[key] = DataBucket.new(value, relative_expires_at(opts[:expires_in]))
            value
          end
        end
      end
      alias_method :incr, :increment

      def key?(key)
        @mutex.synchronize { !fetch_bucket(key).nil? }
      end

      def delete(key)
        @mutex.synchronize { @store.delete(key) }
      end
      alias_method :del, :delete

      private

      def fetch_bucket(key)
        bucket = @store[key]

        return unless bucket
        @store.delete(key) && return if bucket_expired?(bucket)

        bucket
      end

      def bucket_expired?(bucket)
        bucket.expires_at < current_time
      end

      def flush(key)
        bucket = @store[key]

        @store.delete(key) if bucket && bucket_expired?(bucket)
      end

      def current_time
        Time.now.to_i
      end

      def relative_expires_at(expires_in)
        current_time + [expires_in.to_i, sample_window].min
      end
    end
  end
end
