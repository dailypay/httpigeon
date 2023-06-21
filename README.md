# HTTPigeon

As early as 2000 years ago, and as late as 20 years ago, messenger pigeons (a.k.a homing pigeons) were an established and reliable means of long distance communication. This library is dedicated to messenger pigeons and all their contributions towards ancient and modern civilization ❤️.

The goal of this library is to add a layer of abstraction on top of [Faraday](https://github.com/lostisland/faraday) client with a much simpler, but also customizable interface, so that making and logging API requests is much easier.

## Usage

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
# @option [String] base_url the base URI (required)
# @option [Hash] options the Faraday connection options (default: {})
# @option [Hash] headers the request headers (default: {})
# @option [Faraday::Adapter] adapter the Faraday adapter (default: Net::HTTP)
# @option [Logger] logger for logging request and response (default: HTTPigeon::Logger)
# @option [String] event_type for filtering/scoping the logs (default: 'http.outbound')
# @option [Array] filter_keys list of keys in headers and body to be redacted before logging (default: [])
request = HTTPigeon::Request.new(base_url: 'https://dummyjson.com', headers: { Accept: 'application/json' }, filter_keys: [:ssn, :password])
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

  def on_request_start
    @start_time = Time.current
  end

  def on_request_finish
    @end_time = Time.current
  end
end

request = HTTPigeon::Request.new(base_url: 'https://dummyjson.com', logger: CustomLogger.new)
request.run(path: '/users/1')
```

**Using the default logger:**

To use the default logger (`HTTPigeon::Logger`), simply pass a custom `:filter_keys` and `:event_type` args, if necessary, and you're all set.

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
