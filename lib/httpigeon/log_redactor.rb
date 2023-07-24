require "active_support/core_ext/hash"

module HTTPigeon
  class LogRedactor
    def initialize(hash_filter_keys: nil, string_filters: nil)
      @hash_filter_keys = hash_filter_keys.map(&:to_s).map(&:downcase)
      @string_filters = string_filters || []
    end

    def redact(data)
      if data.is_a?(Array)
        data.map { |datum| redact(datum) }
      elsif data.is_a?(String)
        redact_string(data)
      elsif data.is_a?(Hash)
        redact_hash(data)
      else
        data
      end
    end

    private

    attr_reader :hash_filter_keys, :string_filters

    def redact_hash(data)
      data.to_h do |k, v|
        v = HTTPigeon.redactor_string if hash_filter_keys.include?(k.to_s.downcase)

        if v.is_a?(Hash) || v.is_a?(Array)
          [k, redact_hash(v)]
        else
          [k, v]
        end
      end
    end

    def redact_string(data)
      string_filters.each do |filter|
        if filter.sub_prefix.present?
          data = data.gsub(filter.pattern, "#{filter.sub_prefix}#{HTTPigeon.redactor_string}")
        else
          data = data.gsub(filter.pattern, filter.replacement)
        end
      end
  
      data
    end
  end
end
