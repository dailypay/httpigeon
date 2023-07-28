# frozen_string_literal: true

require_relative "lib/httpigeon/version"

Gem::Specification.new do |spec|
  spec.name = "httpigeon"
  spec.version = HTTPigeon::VERSION
  spec.authors = ["2k-joker"]
  spec.email = ["khalil.kum@dailypay.com"]
  spec.licenses = ["MIT"]

  spec.summary = "Simple, easy way to make and log HTTP requests and responses"
  spec.description = "Client library that simplifies making and logging HTTP requests and responses. This library is built as an abstraction on top of the Faraday ruby client."
  spec.homepage = "https://github.com/dailypay/#{spec.name}"
  spec.required_ruby_version = Gem::Requirement.new("~> 3.1.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.pkg.github.com/dailypay"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.7.6"
  spec.add_dependency "activesupport", "~> 7.0.4"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.15"
  spec.add_development_dependency "rubocop-minitest", "~> 0.31.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "pry", "~> 0.13.1"
  spec.add_development_dependency "minitest-stub_any_instance", "~> 1.0.3"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
