# HTTPigeon [![Gem Version](https://badge.fury.io/rb/httpigeon.svg)](https://badge.fury.io/rb/httpigeon)

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
  config.auto_generate_request_id = # Auto-generate a uuid for each request and store in a 'X-Request-Id' header? Default: true
  config.exception_notifier = # Specify an object to be used for reporting errors. Must respond to #notify_exception(e<Exception>). Must be defined if :notify_all_exceptions is true
  config.notify_all_exceptions = # Do you want these errors to actually get reported/notified? Default: false
end
```

**Instantiating with a block:**

- **NOTE:** This pretty much works the same way as passing a block to `Faraday.new`. Any config you can use with `Faraday` directly, you can do with `HTTPigeon::Request`

```ruby
require "faraday/retry"

# @option [String] base_url the base URI (required)
request = HTTPigeon::Request.new(base_url: 'https://dummyjson.com') do |config|
  # config is an instance of Faraday::Connection
  config.headers['foo'] = 'barzzz'
  config.options['timeout'] = 15
  config.request :retry, { max: 5 }
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
request = HTTPigeon::Request.new(base_url: 'https://dummyjson.com', headers: { Accept: 'application/json' }, log_filters: [:api_key, 'access_token', '/(client_id=)(\w+)/'])
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

> [!IMPORTANT]  
> - Log filtering mechanism does partial redaction by default, unless the value is **4 characters or less**. To have a value fully redacted, you have to explicitly append a replacement to the filter, separated by a `::` (e.g `'ssn::[REDACTED]'`). 
> - Hash log filters are case insensitive   
> - Only ignore case regexp flag (`/i`) is currently supported for log filters and is already applied by default

Prior to logging, the default logger will always run it's redactor through:
- The full request **URL**
- The request and response **headers**
- the request and response **body**

**Examples:**

Examples assume you set `:redactor_string` in your initializer to `[REDACTED]`

| Filter | Target | Pre-redaction | Post-redaction | Notes |
| --- | --- | --- | --- | ----- |
| `"email"` OR `:email` | Hash | `{ "email": "atuny0@sohu.com" }` | `{ "email": "atu...[REDACTED]" }` | Filters will get applied to nested objects as well. There's no limit on depth |
| `"email::[REDACTED]"` | Hash | `{ "email": "atuny0@sohu.com" }` | `{ "email": "[REDACTED]" }` | Replacement can be whatever you want and is applied as-is |
| `"/email/"` | Hash | `{ "email": "atuny0@sohu.com" }` | `{ "email": "atuny0@sohu.com" }` | Regex filters will not get applied to hash keys. This is a design decision to prevent bugs |
| `"/(email=)(.*\.[a-z]+)(&\|$)/"` | String | `https://dummyjson.com/users?email=atuny0@sohu.com` | `https://dummyjson.com/users?email=atu...[REDACTED]` | Regex filters must be in proper regex format but wrapped in a string. If no replacement is specified, [regex grouping](https://learn.microsoft.com/en-us/dotnet/standard/base-types/grouping-constructs-in-regular-expressions) MUST be used |
| `"/email=.*\.[a-z]+(&\|$)/::email=[REDACTED]"` | String | `https://dummyjson.com/users?email=atuny0@sohu.com` | `https://dummyjson.com/users?email=[REDACTED]` | Replacement can be whatever you want and is applied as-is. No need to use regex grouping when explicitly specifying a replacement |
| `"(email=)(.*\.[a-z]+)(&\|$)"` OR `"email"` | String | `https://dummyjson.com/users?email=atuny0@sohu.com` | `https://dummyjson.com/users?email=atuny0@sohu.com` | String regex filters must be wrapped in forward slashes(i.e `/[you-regex]/`), otherwise they will be ignored. This is a design descision to prevent bugs |

There are some ready-made, tokenized filter patterns available that you can take advantage of for **URLs** and/or **URI encoded requests**:
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
HTTPigeon::Request.new(base_url: 'https://dummyjson.com', log_filters: %w[access_token password::[REDACTED] /(client_id=)([0-9a-z]+)*/ /password=\w+/::password=[REDACTED]])
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
