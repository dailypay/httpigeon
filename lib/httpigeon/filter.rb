module HTTPigeon
  class Filter
    attr_reader :type, :pattern, :sub_prefix, :replacement

    def initialize(type, pattern, sub_prefix = nil, replacement = nil)
      @type = type
      @pattern = pattern
      @sub_prefix = sub_prefix
      @replacement = replacement
    end
  end
end
