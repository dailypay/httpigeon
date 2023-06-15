module HTTPigeon
  class Configuration
    attr_accessor :default_event_type, :default_filter_keys, :event_logger, :notify_all_exceptions, :exception_notifier

    def initialize
      @default_event_type = 'http.outbound'
      @default_filter_keys = []
      @event_logger = nil
      @notify_all_exceptions = false
      @exception_notifier = nil
    end
  end
end
