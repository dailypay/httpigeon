module HTTPigeon
  module CircuitBreaker
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
        @store.delete(key) && return if bucket.expired?(current_time)

        bucket
      end

      def flush(key)
        bucket = @store[key]

        @store.delete(key) if bucket && bucket.expired?(current_time)
      end

      def current_time
        Time.now.to_i
      end

      def relative_expires_at(expires_in)
        current_time + [expires_in.to_i, sample_window].min
      end
    end

    class DataBucket
      attr_accessor :value, :expires_at

      def initialize(value, expires_at)
        @value = value
        @expires_at = expires_at
      end

      def expired?(current_time = Time.now.to_i)
        expires_at < current_time
      end

      def to_h
        { value: value, expires_at: expires_at }
      end
    end
  end
end
