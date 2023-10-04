require "active_support/core_ext/hash"

module HTTPigeon
  class LogRedactor
    attr_reader :log_filters

    def initialize(log_filters: nil)
      @log_filters = log_filters.to_a.map(&:to_s)
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

    def redact_hash_value(value, redactor_string)
      length = value.to_s.length

      return value unless length.positive?

      case length
      when 1..4
        redactor_string
      when 5..16
        "#{value.to_s[0..2]}...#{redactor_string}"
      when 17..32
        "#{value.to_s[0..(length / 4)]}...#{redactor_string}"
      else
        "#{value.to_s[0..5]}...#{redactor_string}...#{value.to_s[-6..]}"
      end
    end

    def redact_hash(data)
      data.to_h do |k, v|
        filter = log_filter_for(k)
        redactor_string = filter.to_s.split('::')[1].presence || HTTPigeon.redactor_string
        v = redact_hash_value(v, redactor_string) if filter.present?

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
      log_filters.each do |filter|
        pattern, replacement = filter.split('::')

        data = data.gsub(regex(pattern), replacement) if replacement.present?
      end

      data
    end

    def log_filter_for(key)
      log_filters.detect { |k| regex(k.split('::').first).match?(key) }
    end

    def regex(pattern)
      Regexp.new(pattern, Regexp::IGNORECASE)
    end
  end
end
