$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "httpigeon"
require "minitest/autorun"
require "minitest/stub_any_instance"
require "pry"

class HTTPigeon::TestCase < Minitest::Spec
  def self.context(...)
    describe(...)
  end

  def self.let!(name, &block)
    let(name, &block)
    instance_eval { setup { send(name) } }
  end

  def refute_mock(mock)
    assert_raises(MockExpectationError) { mock.verify }
  end
end
