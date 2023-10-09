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
# @param base_url [String] the base URI
# @param options [Hash] the Faraday connection options (default: {})
# @param headers [Hash] the request headers (default: {})
# @param adapter [Faraday::Adapter] the Faraday adapter (default: Net::HTTP)
# @param logger [Logger] for logging request and response (default: HTTPigeon::Logger)
# @param event_type [String] for filtering/scoping the logs (default: 'http.outbound')
# @param log_filters [Array<Symbol, String>] specifies keys in URL, headers and body to be redacted before logging.
#    Can define keys for both Hash and String payloads (default: [])
request = HTTPigeon::Request.new(base_url: 'https://dummyjson.com', headers: { Accept: 'application/json' }, log_filters: [:api_key, 'access_token', '(client_id=)(\w+)'])
request.run(path: '/users/1')
```

**Passing a custom logger:**

Your custom logger must respond to `#log` and be a registered Faraday Middleware. It can optionally implement `#on_request_start` and `#on_request_finish`, if you wanted to take certain actions right before and right after a request round-trip (e.g capturing latency).
Note that if you pass a custom logger, you would have to handle redacting sensitive keys even if you pass a `log_filters` list, unless you subclass `HTTPigeon::Logger`.
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

***Event Type***

The default logger always adds an `:event_type` key to the log payload that can be used as another filtering/grouping mechanism when querying logs. The default value is 'http.outbound'. To set a different value for a specific request, simply pass the key like so:
```ruby
HTTPigeon::Request.new(base_url: 'https://dummyjson.com', event_type: 'custom.event')
```

***Log Filters***

Prior to logging, the default logger will always run it's redactor through:
- The full request **URL**
- The request and response **headers**
- the request and response **body**

There are multiple ways to specify what keys (in Hash) or substrings (in URL or in URI encoded payload) you want redacted
- Simple symbol or string literal (e.g :access_token, "api-key") - will truncate the value of the **hash** key based on it's length
- Simple string literal with a specified replacement (e.g "password::[REDACTED]") - will replace the value of the **hash** key with `[REDACTED]`
- Tokenized regexp (e.g "/(account_number=)(\d+)*/") - will truncate the second token of the **matching substring** based on it's length
- Tokenized regexp with a specified replacement (e.g "/(account_number=)(\d+)*/::[REDACTED]") - will replace the second token of the **matching substring** with `[REDACTED]`
- Simple regexp with a specified replacement (e.g "/account_number=\d+*/::[REDACTED]") - will replace the second token of the **matching substring** with `[REDACTED]`
- Simple regexp without a specified replacement (e.g "/account_number=\d+*/") - will have no effect

***NOTES:***
- A replacement is whatever comes after the `::` separator
- Only ignore case regexp flag (`/i`) is currently supported and is already applied by default
- There are some ready-made, tokenized filter patterns available that you can take advantage of for **URI encoded Strings**:
  - HTTPigeon::FilterPatterns::EMAIL
  - HTTPigeon::FilterPatterns::PASSWORD
  - HTTPigeon::FilterPatterns::USERNAME
  - HTTPigeon::FilterPatterns::CLIENT_ID
  - HTTPigeon::FilterPatterns::CLIENT_SECRET

```ruby
# Will truncate the value of any header or payload key matching access_token
# Will replace the value of any header or payload key matching password with [REDACTED]
# Will truncate the value of any request param URI encoded payload key matching client_id
# Will replace the value of any request param URI encoded payload key matching password with [REDACTED]
HTTPigeon::Request.new(base_url: 'https://dummyjson.com', log_filters: %w[access_token password::[REDACTED] /(client_id=)([0-9a-z]+)*/ /password=\w+/::[REDACTED]])
```

**Running a request:**

* You can pass a block to further customize a specific request:
```ruby
request = HTTPigeon::Request.new(base_url: 'https://dummyjson.com')

# Returns a Hash (parsed JSON) response or a String if the original response was not valid JSON
request.run(path: '/users/1') { |request| request.headers['X-Request-Signature'] = Base64.encode64("#{method}::#{path}") }

# Access the raw Faraday response
request.response

# Quickly get the response status
request.response_status

# Quickly get the raw response body
request.response_body
```
* There is a convenient :get and :post class method you can use
```ruby
# @param endpoint [String] the URI endpoint you're trying to hit
# @param query [Hash] the request query params (default: {})
# @param headers [Hash] the request headers (default: {})
# @param event_type [String] the event type for logs grouping (default: 'http.outbound')
# @param log_filters [Array<Symbol, String>] specifies keys in URL, headers and body to be redacted before logging.
# @return [HTTPigeon::Response] an object with attributes :request [HTTPigeon::Request], :parsed_response [Hash], and :raw_response [Faraday::Response]
response = HTTPigeon::Request.get(endpoint, query, headers, event_type, log_filters)

# @param endpoint [String] the URI endpoint you're trying to hit
# @param payload [Hash] the request payload/body (default: {})
# @param headers [Hash] the request headers (default: {})
# @param event_type [String] the event type for logs grouping (default: 'http.outbound')
# @param log_filters [Array<Symbol, String>] specifies keys in URL, headers and body to be redacted before logging.
# @return [HTTPigeon::Response] an object with attributes :request [HTTPigeon::Request], :parsed_response [Hash], and :raw_response [Faraday::Response]
response = HTTPigeon::Request.post(endpoint, payload, headers, event_type, log_filters)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install:local`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dailypay/httpigeon.

**Making Pull Requests:**

This project uses [release-please](https://github.com/google-github-actions/release-please-action) for automated releases. As such, any pull request that fails the [conventional commits](https://www.conventionalcommits.org/en/v1.0.0-beta.4/#summary) validation will not be merged.
