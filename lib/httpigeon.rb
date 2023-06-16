require "active_support/core_ext/module/delegation"

require "httpigeon/configuration"
require "httpigeon/version"
require "httpigeon/logger"
require "httpigeon/request"

module HTTPigeon
  extend self

  delegate :default_event_type, :default_filter_keys, :event_logger, :notify_all_exceptions, :exception_notifier, to: :configuration

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
