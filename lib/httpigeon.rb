require "active_support/core_ext/module/delegation"

require "httpigeon/configuration"
require "httpigeon/version"
require "httpigeon/log_redactor"
require "httpigeon/logger"
require "httpigeon/request"
require "httpigeon/response"
require "httpigeon/circuit_breaker/fuse"

module HTTPigeon
  extend self

  module FilterPatterns
    EMAIL = "/(?'key'(email_?(address|Address)?=))(?'value'(.*\\.[a-z]+))(&|$)/".freeze
    PASSWORD = "/(?'key'(pass_?(w|W)?ord=))(?'value'([^&$])*)/".freeze
    USERNAME = "/(?'key'(user_?(n|N)?ame=))(?'value'([^&$])*)/".freeze
    CLIENT_ID = "/(?'key'(client_?(id|Id)?=))(?'value'([^&$])*)/".freeze
    CLIENT_SECRET = "/(?'key'(client_?(s|S)?ecret=))(?'value'([^&$])*)/".freeze
  end

  class InvalidConfigurationError < StandardError; end

  delegate :default_event_type,
           :default_filter_keys,
           :redactor_string,
           :log_redactor,
           :event_logger,
           :auto_generate_request_id,
           :notify_all_exceptions,
           :exception_notifier,
           :mount_circuit_breaker,
           :log_circuit_events,
           :fuse_error_codes_watchlist,
           :fuse_on_circuit_open,
           :fuse_max_failures_count,
           :fuse_min_failures_count,
           :fuse_failure_rate_threshold,
           :fuse_sample_window,
           :fuse_open_circuit_sleep_window,
           :fuse_on_open_circuit,
           to: :configuration

  def configure
    @config = HTTPigeon::Configuration.new

    yield(@config) if block_given?

    validate_config(@config)

    @config.freeze
  end

  def stdout_logger
    @stdout_logger ||= ::Logger.new($stdout)
  end

  private

  def configuration
    @configuration ||= @config || HTTPigeon::Configuration.new
  end

  def validate_config(config)
    raise InvalidConfigurationError, "Fuse sleep window: #{config.fuse_open_circuit_sleep_window} must be less than or equal to sample window: #{config.fuse_sample_window}" if fuse_open_circuit_sleep_window > fuse_sample_window
  end
end
