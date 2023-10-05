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

    def redact_value(value)
      length = value.to_s.length

      return value unless length.positive?

      case length
      when 1..4
        HTTPigeon.redactor_string
      when 5..16
        "#{value.to_s[0..2]}...#{HTTPigeon.redactor_string}"
      when 17..32
        "#{value.to_s[0..(length / 4)]}...#{HTTPigeon.redactor_string}"
      else
        "#{value.to_s[0..5]}...#{HTTPigeon.redactor_string}...#{value.to_s[-6..]}"
      end
    end

    def redact_hash(data)
      data.to_h do |k, v|
        filter = log_filter_for(k)

        if filter.present?
          replacement = filter.split('::')[1].presence
          v = replacement.present? ? replacement : redact_value(v)
        end

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

        data = if replacement.present?
                 data.gsub(regex(pattern), replacement)
               else
                 data.gsub(regex(pattern)) do |sub|
                   captures = sub.match(pattern).captures

                   captures.present? ? captures[0] + redact_value(captures[1]) : sub
                 end
               end
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
