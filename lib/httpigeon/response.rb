module HTTPigeon
  class Response
    include Enumerable

    attr_reader :request, :parsed_response, :raw_response

    delegate :each, :to_h, :to_json, :with_indifferent_access, to: :parsed_response
    delegate :status, :body, :env, :headers, to: :raw_response

    def initialize(request, raw_response)
      @request = request
      @raw_response = raw_response

      parse_response
    end

    def ==(other)
      other == parsed_response || other.to_json == to_json || super
    end

    def [](key)
      parsed_response[key]
    end

    private

    def parse_response
      parsable_content_type = headers['content-type'].blank? || headers['content-type'].include?('application/json')
      parsed_body = body.is_a?(String) && parsable_content_type ? JSON.parse(body) : body
      @parsed_response = deep_with_indifferent_access(parsed_body)
    rescue JSON::ParserError
      @parsed_response = body.presence || {}
    end

    def deep_with_indifferent_access(obj)
      case obj
      when Hash
        obj.transform_values do |value|
          deep_with_indifferent_access(value)
        end.with_indifferent_access
      when Array
        obj.map { |item| deep_with_indifferent_access(item) }
      else
        obj
      end
    end
  end
end
