require "active_support/core_ext/hash"

module HTTPigeon
  class LogRedactor
    class UnsupportedRegexpError < StandardError; end

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
        filter = hash_filter_for(k)

        if filter.present?
          replacement = filter.split('::')[1].presence
          # Replace collections wholesale; partial redaction leaks bytes of
          # nested secrets.
          v = if replacement.present?
                replacement
              elsif v.is_a?(Hash) || v.is_a?(Array)
                HTTPigeon.redactor_string
              else
                redact_value(v)
              end
          [k, v]
        else
          # Recurse through the dispatcher so nested values redact like
          # top-level ones. This runs content/regex filters over string
          # values too (e.g. secrets in JSON bodies).
          [k, redact(v)]
        end
      end
    end

    def redact_string(data)
      log_filters.each do |filter|
        pattern, replacement = filter.split('::')

        next unless pattern.match?(%r{^/.*/([guysim]*)$})

        regex = regex_for(pattern)

        data = if replacement.present?
                 # Block form keeps the replacement literal; the string form
                 # expands backreferences (\1, \&) and re-emits the secret.
                 data.gsub(regex) { replacement }
               else
                 data.gsub(regex) do |sub|
                   captures = Regexp.last_match&.captures

                   # A zero-width capture yields nil; skip it rather than
                   # concatenating nil and raising TypeError.
                   if captures.present? && !captures[1].nil?
                     captures[0] + redact_value(captures[1])
                   else
                     sub
                   end
                 end
               end
      end

      data
    end

    def hash_filter_for(key)
      log_filters.detect { |k| k.split('::').first.downcase == key.to_s.downcase }
    end

    def regex_for(pattern)
      regexp_literal = (pattern.match %r{^(/)(.*)(/(i?))$}).to_a[2].to_s

      raise UnsupportedRegexpError, "The specified regexp is invalid: #{pattern}. NOTE: Only ignore case (/i) is currently supported." if regexp_literal.blank?

      Regexp.new(regexp_literal, Regexp::IGNORECASE)
    end
  end
end
