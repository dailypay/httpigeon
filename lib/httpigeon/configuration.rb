module HTTPigeon
  class Configuration
    attr_accessor :default_event_type,
                  :default_filter_keys,
                  :redactor_string,
                  :log_redactor,
                  :event_logger,
                  :notify_all_exceptions,
                  :exception_notifier,
                  :auto_generate_request_id,
                  :mount_circuit_breaker,
                  :log_circuit_events,
                  :fuse_error_codes_watchlist,
                  :fuse_on_circuit_opened,
                  :fuse_on_circuit_closed,
                  :fuse_open_circuit_handler,
                  :fuse_max_failures_count,
                  :fuse_min_failures_count,
                  :fuse_failure_rate_threshold,
                  :fuse_sample_window,
                  :fuse_open_circuit_sleep_window

    def initialize
      @default_event_type = 'http.outbound'
      @default_filter_keys = []
      @redactor_string = '[FILTERED]'
      @log_redactor = nil
      @event_logger = nil
      @auto_generate_request_id = true
      @notify_all_exceptions = false
      @exception_notifier = nil
      @mount_circuit_breaker = false
      @log_circuit_events = true

      @fuse_error_codes_watchlist = []
      @fuse_on_circuit_opened = ->(*_args) {}
      @fuse_on_circuit_closed = ->(*_args) {}
      @fuse_open_circuit_handler = nil
      @fuse_max_failures_count = 10
      @fuse_min_failures_count = 5
      @fuse_failure_rate_threshold = 0.5
      @fuse_sample_window = 60
      @fuse_open_circuit_sleep_window = 30
    end
  end
end
