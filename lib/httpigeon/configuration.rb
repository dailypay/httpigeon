module HTTPigeon
  class Configuration
    attr_accessor :default_event_type, :default_filter_keys, :redactor_string, :log_redactor, :event_logger, :notify_all_exceptions, :exception_notifier, :auto_generate_request_id

    def initialize
      @default_event_type = 'http.outbound'
      @default_filter_keys = []
      @redactor_string = '[FILTERED]'
      @log_redactor = nil
      @event_logger = nil
      @auto_generate_request_id = true
      @notify_all_exceptions = false
      @exception_notifier = nil
    end
  end
end
