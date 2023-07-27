# HTTPigeon

As early as 2000 years ago, and as late as 20 years ago, messenger pigeons (a.k.a homing pigeons) were an established and reliable means of long distance communication. This library is dedicated to messenger pigeons and all their contributions towards ancient and modern civilization ❤️.

The goal of this library is to add a layer of abstraction on top of [Faraday](https://github.com/lostisland/faraday) client with a much simpler, but also customizable interface, so that making and logging API requests is much easier.

## Usage

**Configuration:**
```ruby
HTTPigeon.configure do |config|
  config.default_event_type = # Set a default event type for all requests, overridable per request. Default: 'http.outbound'
  config.default_filter_keys = # Set a default list of keys to be redacted for Hash payloads, overridable per request. Default: []
  config.redactor_string = # Set a string that should be used as the replacement when redacting sensitive data. Default: '[FILTERED]'
  config.log_redactor = # Specify an object to be used for redacting data before logging. Must respond to #redact(data<Hash, String>). Default: nil
  config.event_logger = # Specify an object to be used for logging request roundtrip events. Default: $stdout
  config.auto_generate_request_id = # Auto-generate a uuid for each request and store in a 'X-Request-Id' header?
  config.exception_notifier = # Specify an object to be used for reporting errors. Must respond to #notify_exception(e<Exception>)
  config.notify_all_exceptions = # Do you want these errors to actually get reported/notified?
end
```

**Instantiating with a block:**
```ruby
# @option [String] base_url the base URI (required)
request = HTTPigeon::Request.new(base_url: 'https://dummyjson.com') do |connection|
  # connection is an instance of Faraday::Connection
  connection.headers['foo'] = 'barzzz'
  connection.options['timeout'] = 15
  ...
end

# @option [Symbol] method the HTTP verb (default: :get)
# @option [String] path the request path (default: '/')
# @option [Hash] payload the body (for writes) or query params (for reads) of the request (default: {})
request.run(path: '/users/1')
```

**Instantiating with customizable arguments:**
```ruby
# @param type [Symbol, String] the type of object this filter will be applied to (:hash or :string)
# @param pattern [Symbol, String, Regex] the exact key or pattern that should be redacted
# @param sub_prefix [String] a prefix to be combined with the configured :redactor_string as the replacement for the sensitive data (default: nil)
# @param replacement [String] a string to be used as the replacement for the sensitive data.
#    If :sub_prefix is defined, this value will be ignored (default: nil)
filter_1 = HTTPigeon::Filter.new(:hash, 'access_token')
filter_2 = HTTPigeon::Filter.new(:string, /username=[0-9a-z]*/i, 'username=')
filter_3 = HTTPigeon::Filter.new(:string, /password=[0-9a-z]*/i, nil, 'password=***')

# @param base_url [String] the base URI
# @param options [Hash] the Faraday connection options (default: {})
# @param headers [Hash] the request headers (default: {})
# @param adapter [Faraday::Adapter] the Faraday adapter (default: Net::HTTP)
# @param logger [Logger] for logging request and response (default: HTTPigeon::Logger)
# @param event_type [String] for filtering/scoping the logs (default: 'http.outbound')
# @param filter_keys [Array<String, Symbol>] specifies keys in headers and body to be redacted before logging.
#    Can only define keys for Hash payloads (default: [])
# @param log_filters [Array<HTTPigeon::Filter, Object>] specifies keys in headers and body to be redacted before logging.
#    Can define keys for both Hash and String payloads (default: [])
# @note :filter_keys and :log_filters can both be specified but it is recommended to define all filters using :log_filters
#    if you wish to filter both Hashes and Strings
request = HTTPigeon::Request.new(base_url: 'https://dummyjson.com', headers: { Accept: 'application/json' }, filter_keys: [:ssn, :ip_address], log_filters: [filter_1, filter_2, filter_3])
request.run(path: '/users/1')
```

**Passing a custom logger:**

Your custom logger must respond to `#log` and be a registered Faraday Middleware. It can optionally implement `#on_request_start` and `#on_request_finish`, if you wanted to take certain actions right before and right after a request round-trip (e.g capturing latency).
Note that if you pass a custom logger, you would have to handle redacting sensitive keys even if you pass a `filter_keys` list, unless you subclass `HTTPigeon::Logger`.
```ruby
# The default Rails logger is registered/recognized by Faraday
class CustomLogger < Logger
  # @param [Faraday::Env] env the Faraday environment instance passed from middleware
  # @param [Hash] data additional data passed from middleware. May contain an :error object if the request was unsuccessful (default: {})
  def log(env, data)
    error = data.delete(:error).to_json

    log_data = data.merge(
      {
        method: env.method,
        headers: env.request_headers,
        body: env.response_body,
        error: error,
        latency: @end_time - @start_time
      }
    )

    super(:info, log_data.to_json)
  end

  # optional method
  def on_request_start
    @start_time = Time.current
  end

  # optional method
  def on_request_finish
    @end_time = Time.current
  end
end

request = HTTPigeon::Request.new(base_url: 'https://dummyjson.com', logger: CustomLogger.new)
request.run(path: '/users/1')
```

**Using the default logger:**

To use the default logger (`HTTPigeon::Logger`), simply pass a custom `:filter_keys`, `:log_filters` and `:event_type` args, if necessary, and you're all set.

**Running a request:**

You can pass a block to further customize a specific request:
```ruby
# Returns a Hash (parsed JSON) response or a String if the original response was a string
request.run(path: '/users/1') { |request| request.headers['X-Request-Signature'] = Base64.encode64("#{method}::#{path}") }
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install:local`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dailypay/httpigeon.

**Making Pull Requests:**

This project uses [release-please](https://github.com/google-github-actions/release-please-action) for automated releases. As such, any pull request that fails the [conventional commits](https://www.conventionalcommits.org/en/v1.0.0-beta.4/#summary) validation will not be merged.
