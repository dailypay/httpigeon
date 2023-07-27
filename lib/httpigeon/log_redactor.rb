require "active_support/core_ext/hash"

module HTTPigeon
  class LogRedactor
    attr_reader :hash_filter_keys, :string_filters

    def initialize(hash_filter_keys: nil, string_filters: nil)
      @hash_filter_keys = (hash_filter_keys || []).map(&:to_s).map(&:downcase)
      @string_filters = string_filters || []
    end

    def redact(data)
      case data
      when Array
        data.map { |datum| redact(datum) }
      when String
        redact_string(data)
      when Hash
        redact_hash(data)
      else
        data
      end
    end

    private

    def redact_hash(data)
      data.to_h do |k, v|
        v = HTTPigeon.redactor_string if hash_filter_keys.include?(k.to_s.downcase)

        if v.is_a?(Hash)
          [k, redact_hash(v)]
        elsif v.is_a?(Array)
          [k, v.map { |val| redact(val) }]
        else
          [k, v]
        end
      end
    end

    def redact_string(data)
      string_filters.each do |filter|
        data = if filter.sub_prefix.present?
                 data.gsub(filter.pattern, "#{filter.sub_prefix}#{HTTPigeon.redactor_string}")
               else
                 data.gsub(filter.pattern, filter.replacement)
               end
      end

      data
    end
  end
end
