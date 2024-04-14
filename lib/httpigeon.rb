require "active_support/core_ext/module/delegation"

require "httpigeon/configuration"
require "httpigeon/version"
require "httpigeon/log_redactor"
require "httpigeon/logger"
require "httpigeon/request"
require "httpigeon/response"

module HTTPigeon
  extend self

  module FilterPatterns
    EMAIL = "/(?'key'(email_?(address|Address)?=))(?'value'(.*\\.[a-z]+))(&|$)/".freeze
    PASSWORD = "/(?'key'(pass_?(w|W)?ord=))(?'value'([^&$])*)/".freeze
    USERNAME = "/(?'key'(user_?(n|N)?ame=))(?'value'([^&$])*)/".freeze
    CLIENT_ID = "/(?'key'(client_?(id|Id)?=))(?'value'([^&$])*)/".freeze
    CLIENT_SECRET = "/(?'key'(client_?(s|S)?ecret=))(?'value'([^&$])*)/".freeze
  end

  delegate :default_event_type,
           :default_filter_keys,
           :redactor_string,
           :log_redactor,
           :event_logger,
           :auto_generate_request_id,
           :notify_all_exceptions,
           :exception_notifier,
           to: :configuration

  def configure
    @config = HTTPigeon::Configuration.new

    yield(@config)

    @config.freeze
  end

  private

  def configuration
    @configuration ||= @config || HTTPigeon::Configuration.new
  end
end
